# frozen_string_literal: true

module RecordingJobs
  class TranscodeSchedulerJob < ApplicationJob
    sidekiq_options retry: false

    def perform
      logger = Logger.new Rails.root.join("log/debug_recording_transcode.#{Rails.env}.#{`hostname`.to_s.strip}.log")
      time_start = Time.now.utc
      logger.info("[#{time_start.to_i}] scheduler start: #{time_start} [RecordingJobs::TranscodeSchedulerJob]")

      ids = Recording.where(status: :ready_to_tr).pluck(:id)
      logger.info("[#{time_start.to_i}] ids: #{ids} [RecordingJobs::TranscodeSchedulerJob]")
      ids.each do |recording_id|
        if SidekiqSystem::Queue.exists?(RecordingJobs::TranscodeWorkerJob, recording_id)
          logger.info("[#{time_start.to_i}] #{recording_id} TranscodeWorkerJob is already scheduled [RecordingJobs::TranscodeSchedulerJob]")
          next
        end

        if SidekiqSystem::Workers.job_running?(RecordingJobs::TranscodeWorkerJob, recording_id)
          logger.info("[#{time_start.to_i}] #{recording_id} TranscodeWorkerJob is still running [RecordingJobs::TranscodeSchedulerJob]")
          next
        end

        RecordingJobs::TranscodeWorkerJob.perform_async(recording_id)
        logger.info("[#{time_start.to_i}] worker scheduled #{recording_id} [RecordingJobs::TranscodeSchedulerJob]")
      end

      time_end = Time.now.utc
      logger.info("[#{time_start.to_i}] end: #{time_end} | #{time_start} (#{time_end - time_start} seconds) [RecordingJobs::TranscodeSchedulerJob]")
    end
  end
end
