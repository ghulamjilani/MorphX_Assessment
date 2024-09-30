# frozen_string_literal: true

class Webhook::V1::TransferServerController < Api::V1::ApplicationController
  skip_before_action :authorization, only: [:create], if: -> { request.headers['Authorization'].blank? }

  def create
    if params[:status].to_i == 200
      success_video_transfer
    else
      error_video_transfer
    end
    head :ok
  end

  private

  # curl --header "Content-Type: application/json"     --request POST     --data "{\"filename\":\"68dcd67504c1af3ac_type\":\"video\",\"width\":1920,\"height\":1080},{\"codec_type\":\"audio\"}]},\"status\":200,\"body\":\"OK\",\"ident\":\"131\",\"from\":\"video_transfer\",\"controller\":\"web_hook/replays\",\"action\":\"create\",\"format\":\"json\"}"     http://localhost:3001/web_hook/replays
  def success_video_transfer
    video = Video.find(params[:ident])
    crop_seconds = if video.room&.became_active_at.nil? || video.ffmpegservice_starts_at.nil? || video.room.zoom?
                     0
                   else
                     seconds = (Time.parse(video.ffmpegservice_starts_at) - video.room.became_active_at).to_i.abs
                     seconds = ((seconds > video.duration / 1000) ? 0 : seconds) if video.duration
                     seconds
                   end

    begin
      video_resolutions = params[:file_info][:streams].select { |obj| obj[:codec_type] == 'video' }
      audio_resolutions = params[:file_info][:streams].select { |obj| obj[:codec_type] == 'audio' }
      width = video_resolutions.map { |obj| obj['width'].to_i }.max
      height = video_resolutions.map { |obj| obj['height'].to_i }.max
    rescue StandardError
      width = height = nil
      audio_resolutions = []
      video_resolutions = []
    end

    if audio_resolutions.blank? && video_resolutions.present?
      video.update_columns({
                             status: Video::Statuses::ERROR,
                             ffmpegservice_reason: 'No audio',
                             error_reason: 'original_no_audio'
                           })
    else
      video.update(status: Video::Statuses::DOWNLOADED)
    end

    video.update_columns({
                           width: width,
                           height: height,
                           crop_seconds: crop_seconds,
                           original_name: params[:filename]
                         })
    # remove files from ffmpegservice if this is ffmpegservice stream
    if video.session.ffmpegservice? && !Rails.application.credentials.backend.dig(:initialize, :ffmpegservice_account, :recordings, :delete_disabled)
      if Ffmpeg.valid?(video.ffmpegservice_download_url)
        wa = FfmpegserviceAccount.find_by(stream_id: video.ffmpegservice_transcoder_id)
        Sender::Ffmpegservice.client(account: wa).delete_recording(video.ffmpegservice_id) if wa.present?
      else
        video.update(status: Video::Statuses::ERROR, error_reason: 'original_corrupted')
        SystemReportMailer.video_is_corrupted('Video', video.id).deliver_now
      end
    elsif video.zoom_id.present? && !video.session.records.exists?(status: [Video::Statuses::TRANSFER, Video::Statuses::FOUND])
      # remove files from zoom if this is zoom stream and all other videos of this session uploaded
      Sender::ZoomLib.new(identity: video.organizer.zoom_identity).delete_recordings(video.session.zoom_meeting.meeting_id)
    elsif video.session.webrtcservice?
      client = Sender::Webrtcservice::Video.client
      composition = client.composition(video.ffmpegservice_id)
      webrtcservice_room = WebrtcserviceRoom.new(sid: composition[:room_sid])
      Control::WebrtcserviceRoom.new(webrtcservice_room).delete_recordings
      client.delete_composition(composition[:sid])
    end
  end

  def error_video_transfer
    begin
      video = Video.find_by(id: params[:ident])
      video.update_columns({ status: Video::Statuses::ERROR, error_reason: 'transfer_error' })
    rescue StandardError => e
      nil
    end
    Airbrake.notify('error_video_transfer', parameters: { params: params })
  end
end
