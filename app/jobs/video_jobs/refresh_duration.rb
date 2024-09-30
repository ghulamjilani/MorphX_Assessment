# frozen_string_literal: true

class VideoJobs::RefreshDuration < ApplicationJob
  def perform(id)
    debug_logger(:start)
    begin
      video = Video.find id
      return unless video&.hls_main&.present?

      duration_in_seconds = JSON.parse(`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 '#{video.url}'`).to_f
      duration_in_miliseconds = (duration_in_seconds * 1000).to_i
      updated = false
      updated = video.update(duration: duration_in_miliseconds) if duration_in_miliseconds.present?
      debug_logger('fix result',
                   results: {
                     id: id,
                     duration_in_miliseconds: duration_in_miliseconds,
                     updated: updated
                   })
    rescue StandardError => e
      debug_logger('fix error', e)
      Airbrake.notify(e,
                      {
                        message: 'Failed to update video duration',
                        video_id: id
                      })
    end
    debug_logger(:end)
  end
end
