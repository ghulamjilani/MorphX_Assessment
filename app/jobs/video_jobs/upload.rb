# frozen_string_literal: true

class VideoJobs::Upload < ApplicationJob
  def perform
    Video.joins(:room).where(status: Video::Statuses::FOUND, rooms: { service_type: %w[ipcam rtmp mobile webrtc] })
         .where(ffmpegservice_state: %w[completed no_video]).find_each do |video|
      case video.ffmpegservice_state
      when 'completed'
        if Ffmpeg.valid?(video.ffmpegservice_download_url)
          video.update_attribute(:status, Video::Statuses::TRANSFER)
          Sender::TransferServer.client.transfer({ url: video.ffmpegservice_download_url,
                                                   path: "#{video.user_id}/#{video.room_id}", ident: video.id })
        else
          video.update(status: Video::Statuses::ERROR, error_reason: 'original_corrupted')
          SystemReportMailer.video_is_corrupted('Video', video.id).deliver_now
        end
      when 'no_video'
        video.update(status: Video::Statuses::ERROR, error_reason: 'original_no_video')
        wa = FfmpegserviceAccount.find_by(stream_id: video.ffmpegservice_transcoder_id)
        Sender::Ffmpegservice.client(account: wa).delete_recording(video.ffmpegservice_id) if wa.present?
      end
    end

    webrtcservice_client = Sender::Webrtcservice::Video.client
    Video.joins(:room).where(status: Video::Statuses::FOUND, ffmpegservice_state: 'completed',
                             rooms: { service_type: ['webrtcservice'] }).find_each do |video|
      composition_media_url = webrtcservice_client.composition_media_url(video.ffmpegservice_id)
      video.update(status: Video::Statuses::TRANSFER, ffmpegservice_download_url: composition_media_url)
      Sender::TransferServer.client.transfer({ url: composition_media_url, path: "#{video.user_id}/#{video.room_id}",
                                               ident: video.id, service: 'webrtcservice' })
    end

    # possible status only completed
    Video.joins(:room).where(status: Video::Statuses::FOUND).where(zoom_state: %w[completed]).find_each do |video|
      video.update_attribute(:status, Video::Statuses::TRANSFER)
      Sender::TransferServer.client.transfer({ url: video.zoom_download_url,
                                               path: "#{video.user_id}/#{video.room_id}", ident: video.id })
    end
  end
end
