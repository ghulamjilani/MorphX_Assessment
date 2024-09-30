# frozen_string_literal: true

module TranscodableJobs
  class PingStatusesJob < ApplicationJob
    def perform
      job_ids = TranscodeTask.not_completed.pluck(:job_id)
      return if job_ids.blank?

      statuses = Sender::Qencode.client.statuses(job_ids)
      statuses.each_key do |job_id|
        next unless (transcode_task = TranscodeTask.find_by(job_id:))

        task_info = statuses[job_id]
        transcode_task.update(
          status: task_info[:status],
          percent: task_info[:percent],
          error: task_info[:error],
          error_description: task_info[:error_description]
        )
      end
    end
  end
end
