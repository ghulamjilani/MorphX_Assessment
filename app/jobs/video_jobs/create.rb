# frozen_string_literal: true

class VideoJobs::Create < ApplicationJob
  #=> {"id"=>"2j9FVPt1", "state"=>"no_video", "transcoder_id"=>"0zjmkytw", "transcoder_name"=>"QA", "starts_at"=>"2018-03-13T20:03:51.000Z", "transcoding_uptime_id"=>"lj9693cs", "file_size"=>0, "duration"=>0, "reason"=>"No DVR cache found", "created_at"=>"2018-03-13T20:10:47.000Z", "updated_at"=>"2018-03-13T20:10:47.000Z", "links"=>[{"rel"=>"self", "method"=>"GET", "href"=>"https://api.cloud.ffmpegservice.com/api/v1.1/recordings/2j9FVPt1"}, {"rel"=>"state", "method"=>"GET", "href"=>"https://api.cloud.ffmpegservice.com/api/v1.1/recordings/2j9FVPt1/state"}, {"rel"=>"delete", "method"=>"DELETE", "href"=>"https://api.cloud.ffmpegservice.com/api/v1.1/recordings/2j9FVPt1"}]}
  #=> {"id"=>"PPvVW0Km", "state"=>"completed", "transcoder_id"=>"vrpzdyjj", "transcoder_name"=>"2018-04-03 16:48:27", "starts_at"=>"2018-04-22T20:50:22.000Z", "transcoding_uptime_id"=>"lnctq2pw", "file_name"=>"c04b2f15.0.mp4", "file_size"=>1945079653, "duration"=>4923971, "download_url"=>"https://storage.googleapis.com/prod-wse-recordings/transcoder_950066/1250883_c04b2f15.0.mp4", "reason"=>"", "created_at"=>"2018-04-22T22:15:08.000Z", "updated_at"=>"2018-04-22T22:21:15.000Z", "links"=>[{"rel"=>"self", "method"=>"GET", "href"=>"https://api.cloud.ffmpegservice.com/api/v1.1/recordings/PPvVW0Km"}, {"rel"=>"state", "method"=>"GET", "href"=>"https://api.cloud.ffmpegservice.com/api/v1.1/recordings/PPvVW0Km/state"}, {"rel"=>"delete", "method"=>"DELETE", "href"=>"https://api.cloud.ffmpegservice.com/api/v1.1/recordings/PPvVW0Km"}]}
  # ffmpegservice_id
  # ffmpegservice_transcoder_id
  # ffmpegservice_transcoder_name
  # ffmpegservice_state
  # ffmpegservice_starts_at
  # ffmpegservice_reason
  def perform
    client = Sender::Ffmpegservice.client(sandbox: %w[qa production].exclude?(Rails.env))
    client.recordings.to_a.each do |obj|
      next unless (ffmpegservice_account = FfmpegserviceAccount.find_by(stream_id: obj[:transcoder_id]))

      next unless (recording = client.recording(obj[:id]))

      video = Video.find_or_initialize_by(ffmpegservice_id: recording[:id])
      if video.new_record?
        video.transcoding_uptime_id = recording[:transcoding_uptime_id]
        video.ffmpegservice_transcoder_id = recording[:transcoder_id]
        video.ffmpegservice_transcoder_name = recording[:transcoder_name]
        video.ffmpegservice_reason = recording[:reason]
        video.ffmpegservice_starts_at = recording[:starts_at]
        video.original_size = recording[:file_size]

        session = Session.joins(:room)
                         .where(ffmpegservice_account_id: ffmpegservice_account.id)
                         .where(':time_now BETWEEN (rooms.actual_start_at - (5 * interval \'1 minute\'))::timestamp AND rooms.actual_end_at::timestamp', { time_now: recording[:starts_at] }).last

        if (uptime = TranscoderUptime.for_rooms.find_by(uptime_id: recording[:transcoding_uptime_id]))
          room = uptime.streamable
          video.room_id = room.id
          video.user_id = room.presenter_user_id
          video.status = Video::Statuses::FOUND
        elsif session
          video.room_id = session.room_id
          video.user_id = session.presenter.user_id
          video.status = Video::Statuses::FOUND
        elsif (uptime = TranscoderUptime.for_stream_previews.find_by(uptime_id: recording[:transcoding_uptime_id])) ||
              ffmpegservice_account.stream_previews.exists?([
                                                      ':recording_starts_at BETWEEN (created_at::timestamp - (1 * interval \'10 seconds\')) AND (created_at + (1 * interval \'1 minute\'))::timestamp', { recording_starts_at: recording[:starts_at] }
                                                    ])
          Sender::Ffmpegservice.client(account: ffmpegservice_account).delete_recording(recording[:id])
          next
        else
          video.status = Video::Statuses::ERROR
          video.error_reason = 'room_not_found'
          rooms = Room.where(
            ':time_now BETWEEN (actual_start_at - (20 * interval \'1 minute\'))::timestamp AND actual_end_at::timestamp', { time_now: recording[:starts_at] }
          ).pluck(:id)
          Airbrake.notify("CreateVideoJob: Can't find room or user",
                          parameters: {
                            possible_rooms: rooms,
                            recording: recording.inspect
                          })
        end
      end
      video.duration = (recording[:duration].to_i.zero? ? nil : recording[:duration].to_i)
      video.ffmpegservice_download_url = recording[:download_url]
      video.ffmpegservice_state = recording[:state]
      video.save
    rescue StandardError => e
      Airbrake.notify(e,
                      parameters: {
                        recording: obj
                      })
    end
  end
end
