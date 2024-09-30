# frozen_string_literal: true

class VideoJobs::FindBrokenVideos < ApplicationJob
  def perform(id = nil)
    unless id
      check_interval = Rails.application.credentials.backend.dig(:broken_videos_job_check_days_interval) || 30
      limit = Rails.application.credentials.backend.dig(:broken_videos_job_chunk_size) || 100
      ids = Video.available.where('checked_at IS NULL OR checked_at < ?',
                                  check_interval.days.ago).order(checked_at: :asc).limit(limit).pluck(:id)
      ids.each { |id| VideoJobs::FindBrokenVideos.perform_async(id) }
      return
    end

    video = Video.find_by(id: id)

    raise 'NOTFOUND' unless video
    raise 'HLSEMPTY' if video.hls_main.blank?

    # https://vod.unite.live/138/channels/90/a1202bc89d7719ef9cf1e800cf082dfc/playlist.m3u8
    url = "https://#{ENV['HWCDN']}#{video.hls_main}"

    playlist_resp = Excon.get(url)
    unless playlist_resp.status.to_s == '200'
      raise 'ERRORURL'
    end

    # video_4.m3u8
    chunk_playlist_path = playlist_resp.body.split("\n").last

    # https://vod.unite.live/138/channels/90/a1202bc89d7719ef9cf1e800cf082dfc/video_4.m3u8
    chunk_playlist_url = URI.join(url, chunk_playlist_path).to_s

    chunk_list_resp = Excon.get(chunk_playlist_url)
    unless chunk_list_resp.status.to_s == '200'
      raise 'ERRORPLAYLIST'
    end

    chunk_paths = chunk_list_resp.body.split("\n")

    # video_4/18.ts
    chunk_path = chunk_paths.reverse.find { |path| !path.start_with?('#') }
    raise 'ERRORCHUNKPATH' unless chunk_path

    # https://vod.unite.live/138/channels/90/a1202bc89d7719ef9cf1e800cf082dfc/video_4/18.ts
    chuck_url = URI.join(chunk_playlist_url, chunk_path).to_s
    unless Excon.get(chuck_url).status.to_s == '200'
      raise 'ERRORCHUNC'
    end

    video.touch(:checked_at)
    "video #{id} OK"
  rescue StandardError => e
    message = case e.message
              when 'NOTFOUND'
                "VideoJobs::FindBrokenVideos: Can't find Video #{id}"
              when 'HLSEMPTY'
                "VideoJobs::FindBrokenVideos: Video #{id} hls_main url empty"
              when 'ERRORURL'
                "VideoJobs::FindBrokenVideos: Can't get chunk list from url #{url}"
              when 'ERRORPLAYLIST'
                "VideoJobs::FindBrokenVideos: Can't get video chunks from url #{chunk_playlist_url}"
              when 'ERRORCHUNKPATH'
                "VideoJobs::FindBrokenVideos: Can't get video chunk path from playlist #{chunk_playlist_url}"
              when 'ERRORCHUNC'
                "VideoJobs::FindBrokenVideos: Can't get video chunk from url #{chuck_url}"
              else
                "VideoJobs::FindBrokenVideos job error: #{e.message}"
              end

    Airbrake.notify(e,
                    parameters: {
                      video_id: id,
                      message: message
                    })
    video.touch(:checked_at)
    "video #{id} FAIL: #{e.message}"
  end
end
