# frozen_string_literal: true

class VideoJobs::Delete < ApplicationJob
  def perform(force = false)
    time = if force
             Time.now
           elsif Rails.env.production?
             Time.now - 1.week
           else
             Time.now - 30.minutes
           end
    Video.where('deleted_at < ?', time).find_each do |video|
      video.destroy!
    rescue StandardError => e
      Airbrake.notify(e, parameters: { video_id: video.id })
    end
  end
end
