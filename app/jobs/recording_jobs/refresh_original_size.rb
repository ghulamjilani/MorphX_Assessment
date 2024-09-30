# frozen_string_literal: true

class RecordingJobs::RefreshOriginalSize < ApplicationJob
  def perform
    Recording.where(original_size: [0, nil], deleted_at: nil).find_each do |recording|
      recording.update(original_size: recording.file.byte_size)
    rescue StandardError => e
      Airbrake.notify(e, { message: 'Failed to update recording recording original_size', recording_id: recording.id })
    end
  end
end
