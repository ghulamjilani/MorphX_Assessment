# frozen_string_literal: true

class VideoJobs::CreateZoom < ApplicationJob
  #=> {"id"=>"2j9FVPt1", "state"=>"no_video", "transcoder_id"=>"0zjmkytw", "transcoder_name"=>"QA", "starts_at"=>"2018-03-13T20:03:51.000Z", "transcoding_uptime_id"=>"lj9693cs", "file_size"=>0, "duration"=>0, "reason"=>"No DVR cache found", "created_at"=>"2018-03-13T20:10:47.000Z", "updated_at"=>"2018-03-13T20:10:47.000Z", "links"=>[{"rel"=>"self", "method"=>"GET", "href"=>"https://api.cloud.ffmpegservice.com/api/v1.1/recordings/2j9FVPt1"}, {"rel"=>"state", "method"=>"GET", "href"=>"https://api.cloud.ffmpegservice.com/api/v1.1/recordings/2j9FVPt1/state"}, {"rel"=>"delete", "method"=>"DELETE", "href"=>"https://api.cloud.ffmpegservice.com/api/v1.1/recordings/2j9FVPt1"}]}
  #=> {"id"=>"PPvVW0Km", "state"=>"completed", "transcoder_id"=>"vrpzdyjj", "transcoder_name"=>"2018-04-03 16:48:27", "starts_at"=>"2018-04-22T20:50:22.000Z", "transcoding_uptime_id"=>"lnctq2pw", "file_name"=>"c04b2f15.0.mp4", "file_size"=>1945079653, "duration"=>4923971, "download_url"=>"https://storage.googleapis.com/prod-wse-recordings/transcoder_950066/1250883_c04b2f15.0.mp4", "reason"=>"", "created_at"=>"2018-04-22T22:15:08.000Z", "updated_at"=>"2018-04-22T22:21:15.000Z", "links"=>[{"rel"=>"self", "method"=>"GET", "href"=>"https://api.cloud.ffmpegservice.com/api/v1.1/recordings/PPvVW0Km"}, {"rel"=>"state", "method"=>"GET", "href"=>"https://api.cloud.ffmpegservice.com/api/v1.1/recordings/PPvVW0Km/state"}, {"rel"=>"delete", "method"=>"DELETE", "href"=>"https://api.cloud.ffmpegservice.com/api/v1.1/recordings/PPvVW0Km"}]}
  # ffmpegservice_id
  # ffmpegservice_transcoder_id
  # ffmpegservice_transcoder_name
  # ffmpegservice_state
  # ffmpegservice_starts_at
  # ffmpegservice_reason
  def perform
    Session.vod.joins(:room, :zoom_meeting).where(rooms: { vod_is_fully_ready: false }).find_each do |session|
      room = session.room
      meeting = session.zoom_meeting
      identity = session.organizer.zoom_identity
      next unless identity

      sender = Sender::ZoomLib.new(identity: identity)
      recordings = begin
        sender.meeting_recordings(meeting.meeting_id)
      rescue StandardError
        []
      end
      recordings['recording_files'].select { |r| r['file_type'] == 'MP4' }.each do |recording|
        video = Video.find_or_initialize_by(zoom_id: recording['id'])
        if video.new_record?
          video.zoom_download_url = "#{recording['download_url']}?access_token=#{sender.access_token}"
          video.zoom_state = recording['status']
          video.zoom_start_at = recording['recording_start']
          video.zoom_end_at = recording['recording_end']
          video.original_size = recording['file_size']
          video.duration = (video.zoom_end_at - video.zoom_start_at) * 1000
        end
        video.room_id = room.id
        video.user_id = session.presenter.user_id
        video.status = Video::Statuses::FOUND
        video.save
      end
    end
  end
end
