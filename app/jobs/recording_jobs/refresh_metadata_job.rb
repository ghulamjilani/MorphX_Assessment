# frozen_string_literal: true

class RecordingJobs::RefreshMetadataJob < ApplicationJob
  def perform(id)
    recording = Recording.find(id)
    analyzer = begin
      ActiveStorage::Analyzer::VideoAnalyzer.new(recording.file.blob).metadata
    rescue StandardError
      {}
    end
    recording.width = analyzer[:width].to_i
    recording.height = analyzer[:height].to_i
    recording.duration = (analyzer[:duration].to_f * 1000).to_i
    recording.original_size = recording.file.byte_size
    recording.size = recording.file.byte_size
    recording.save
  end
end
