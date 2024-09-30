# frozen_string_literal: true

module TranscodableJobs
  class UpdateTranscodeTaskStatusJob < ApplicationJob
    def perform(transcode_task_id)
      return unless (transcode_task = TranscodeTask.find_by(id: transcode_task_id))

      control = ::Control::TranscodeTask.new(transcode_task)
      control.update_status
    end
  end
end
