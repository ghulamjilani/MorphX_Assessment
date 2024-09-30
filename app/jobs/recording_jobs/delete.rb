# frozen_string_literal: true

module RecordingJobs
  class Delete < ApplicationJob
    def perform
      time = if Rails.env.production?
               Time.now - 3.days
             else
               Time.now - 30.minutes
             end
      Recording.where('deleted_at < ?', time).find_each do |recording|
        recording.destroy!
      rescue StandardError => e
        Airbrake.notify(e, parameters: { recording_id: recording.id })
      end
    end
  end
end
