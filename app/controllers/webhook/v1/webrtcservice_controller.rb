# frozen_string_literal: true

class Webhook::V1::WebrtcserviceController < ActionController::Base
  skip_before_action :verify_authenticity_token
  before_action :set_room

  def create
    if token_valid? && @room
      data = params.to_unsafe_h
      debug_logger(params[:StatusCallbackEvent], data) if log_enabled?
      case params[:StatusCallbackEvent]
      when 'room-created'
        room_created
      when 'room-ended'
        room_ended
      when 'participant-connected'
        participants_updated
      when 'participant-disconnected'
        participants_updated
        participant_disconnected
      end
    end
    head :ok
  end

  private

  def token_valid?
    return true if Rails.env.test?

    params[:token].present? && params[:token] == Rails.application.credentials.backend.dig(:initialize, :webrtcservice,
                                                                                           :webhook, :token)
  end

  def debug_logger(name, data = {})
    @custom_logger ||= Logger.new "#{Rails.root}/log/#{self.class.to_s.underscore.tr('/',
                                                                                     '_')}.#{Time.now.utc.strftime('%Y-%m')}.#{Rails.env}.#{`hostname`.to_s.strip}.log"
    @custom_logger.debug("[#{request&.remote_ip}]: #{name} | #{data}")
    puts "[#{self.class}][#{Time.now.utc}][#{request&.remote_ip}]: #{name} | #{data}"
  rescue StandardError => e
    Airbrake.notify(e)
  end

  def log_enabled?
    Rails.application.credentials.backend.dig(:initialize, :webrtcservice, :webhook, :log)
  end

  # {
  #   "RoomStatus":"in-progress",
  #   "RoomType":"group",
  #   "RoomSid":"RMb2ed0bd9f12e63f217164b86b71d3186",
  #   "RoomName":"{\"s\":\"qa.morphx\",\"e\":\"QA\",\"i\":34}",
  #   "SequenceNumber":"0",
  #   "StatusCallbackEvent":"room-created",
  #   "Timestamp":"2021-02-19T13:00:46.566Z",
  #   "AccountSid":"AC2df6e5baadb9e338f6f0487bcb379f67",
  #   "controller":"webhook/v1/webrtcservice",
  #   "action":"create"
  # }
  def room_created
    @webrtcservice_room&.update(status: params[:RoomStatus])
  end

  # {
  #   "RoomStatus":"completed",
  #   "RoomType":"group",
  #   "RoomSid":"RMc43a02b1f8c34814e1cdd45797654c17",
  #   "RoomName":"{\"s\":\"AndreyShDev\",\"e\":\"DE\",\"i\":143}",
  #   "RoomDuration":"2161",
  #   "SequenceNumber":"47",
  #   "StatusCallbackEvent":"room-ended",
  #   "Timestamp":"2021-02-19T13:30:25.862Z",
  #   "AccountSid":"AC2df6e5baadb9e338f6f0487bcb379f67",
  #   "controller":"webhook/v1/webrtcservice",
  #   "action":"create"
  # }
  def room_ended
    @webrtcservice_room&.update(status: params[:RoomStatus])
    if @room&.active?
      @room.closed!
      @session.update_columns(stop_reason: 'webhook_room_ended')
      unless @room.recorder_empty?
        @room.stop_record!
      end
    end
  end

  # {
  #   "RoomStatus":"in-progress",
  #   "RoomType":"group",
  #   "RoomSid":"RM6b04b99e430ad272dd1f984688be278e",
  #   "RoomName":"{\"s\":\"qa.morphx\",\"e\":\"QA\",\"i\":44}",
  #   "ParticipantStatus":"connected",
  #   "ParticipantIdentity":"{\"id\":23,\"rl\":\"U\"}",
  #   "SequenceNumber":"15",
  #   "StatusCallbackEvent":"participant-connected",
  #   "Timestamp":"2021-02-24T12:59:34.503Z",
  #   "ParticipantSid":"PA117088a19a51d923b93ecef6ffe1e609",
  #   "AccountSid":"AC2df6e5baadb9e338f6f0487bcb379f67",
  #   "controller":"webhook/v1/webrtcservice",
  #   "action":"create"
  # }
  def participants_updated
    return unless @room&.active? && @webrtcservice_room

    presenter_connected = Control::WebrtcserviceRoom.new(@webrtcservice_room).presenter_connected?

    @room.clear_no_presenter_stop_scheduled_cache

    stop_scheduled = SidekiqSystem::Schedule.exists?(SessionJobs::StopNoPresenterSession, @room.id)

    if presenter_connected && stop_scheduled
      SidekiqSystem::Schedule.remove(SessionJobs::StopNoPresenterSession, @room.id)
      SidekiqSystem::Schedule.remove(SessionJobs::StopNoPresenterNotificationJob, @room.id)
      PresenceImmersiveRoomsChannel.broadcast_to(@room, event: 'presenter_joined', data: {})
    elsif !presenter_connected && !stop_scheduled
      autostop_at = 15.minutes.from_now
      if autostop_at < @room.actual_end_at
        SessionJobs::StopNoPresenterSession.perform_at(autostop_at, @room.id)
        SessionJobs::StopNoPresenterNotificationJob.perform_at((autostop_at - 5.minutes), @room.id)
      end
    end
  end

  def participant_disconnected
    return unless @room&.active? && @webrtcservice_room

    identity = Webrtcservice::Video::Participant.decode_identity(params[:ParticipantIdentity])
    if identity['id'].blank? && (rm = RoomMember.find_by(id: identity['mid']))
      rm.destroy
    end
  end

  def set_room
    decoded = WebrtcserviceRoom.new(unique_name: params[:RoomName]).decode_name
    return unless (@room = decoded[:room])

    @session = @room.abstract_session
    @webrtcservice_room = WebrtcserviceRoom.find_or_create_by(session: @session, unique_name: params[:RoomName], sid: params[:RoomSid])
  end
end
