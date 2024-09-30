# frozen_string_literal: true

module SessionJobs
  class PingLivestream < ApplicationJob
    sidekiq_options queue: :critical

    def perform(room_id)
      room = Room.find(room_id)
      stream_state = 'off'
      stream_url = nil
      connected = nil

      @session = room.abstract_session
      if room.zoom?
        connected_zoom_account = @session.organizer.zoom_identity
        raise 'No Zoom Account found' if connected_zoom_account.blank?

        sender = Sender::ZoomLib.new(identity: connected_zoom_account)
        meeting = sender.meeting(@session.zoom_meeting.meeting_id)
        stream_state = transcoder_status = ((meeting['status'] == 'started') ? 'up' : 'off')
      elsif @session.webrtcservice?
        room_data = @session.webrtcservice_client.room(nil, expected_status: [200, 404])
        if room_data.present?
          webrtcservice_room = @session.webrtcservice_rooms.find_or_create_by(sid: room_data['sid'])
          Control::WebrtcserviceRoom.new(webrtcservice_room).sync_room(room_data)
        end
        stream_state = transcoder_status = ((room_data[:status] == 'in-progress') ? 'up' : 'off')
      elsif (wa = room.ffmpegservice_account)
        wa_client = Sender::Ffmpegservice.client(account: wa)
        state_stream = wa_client.state_transcoder.to_h.with_indifferent_access
        wa.host_ip = state_stream[:ip_address] if state_stream.present? && wa.host_ip != state_stream[:ip_address]
        transcoder_status = state_stream[:state]
        case transcoder_status
        when 'started', 'stopping', 'resetting'
          if (connected = wa_client.transcoder_active?)
            wa.stream_up!
            stream_url = wa.hls_url if room.active?
            @session.remove_stop_no_stream_job
          else
            wa.stream_down!
            @session.schedule_stop_no_stream_job if room.active?
          end
        when 'starting'
          wa.stream_starting!
        else
          wa.stream_off!
        end
        stream_state = wa.stream_status
      end

      case stream_state
      when 'up'
        @session.service_status_up! unless @session.service_status_up?
        event = room.active? ? 'livestream-up' : 'livestream-down'
      when 'down'
        @session.service_status_down! unless @session.service_status_down?
        event = 'livestream-down'
      else
        @session.service_status_off! unless @session.service_status_off?
        event = 'livestream-down'
      end

      PrivateLivestreamRoomsChannel.broadcast_to room, event: event,
                                                       data: { active: room.active?, transcoder_status: transcoder_status, connected: connected, stream_url: stream_url }
      PublicLivestreamRoomsChannel.broadcast_to room, event: event,
                                                      data: { active: room.active?, transcoder_status: transcoder_status, connected: connected }
      SessionsChannel.broadcast event,
                                { session_id: @session.id, active: room.active?,
                                  transcoder_status: transcoder_status }

      if (room.actual_end_at + 1.minutes) > Time.now
        SidekiqSystem::Schedule.remove(SessionJobs::PingLivestream, room_id)
        SessionJobs::PingLivestream.perform_at(((stream_state == 'up') ? 30 : 10).seconds.from_now, room.id) unless Rails.env.test?
      end
    end
  end
end
