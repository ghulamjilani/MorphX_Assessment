# frozen_string_literal: true

module VideoJobs
  class TranscodeSchedulerJob < ApplicationJob
    sidekiq_options retry: false

    def perform
      logger = Logger.new Rails.root.join("log/debug_video_transcode.#{Rails.env}.#{`hostname`.to_s.strip}.log")
      time_start = Time.now.utc
      logger.info("[#{time_start.to_i}] scheduler start: #{time_start} [VideoJobs::TranscodeSchedulerJob]")
      ids = Video.where(status: Video::Statuses::READY_TO_TR).pluck(:id)
      logger.info("[#{time_start.to_i}] ids: #{ids} [VideoJobs::TranscodeSchedulerJob]")
      ids.each do |video_id|
        if SidekiqSystem::Queue.exists?(VideoJobs::TranscodeWorkerJob, video_id)
          logger.info("[#{time_start.to_i}] #{video_id} TranscodeWorkerJob is already scheduled")
          next
        end

        if SidekiqSystem::Workers.job_running?(VideoJobs::TranscodeWorkerJob, video_id)
          logger.info("[#{time_start.to_i}] #{video_id} TranscodeWorkerJob is still running")
          next
        end

        VideoJobs::TranscodeWorkerJob.perform_async(video_id)
        logger.info("[#{time_start.to_i}] worker scheduled #{video_id} [VideoJobs::TranscodeSchedulerJob]")
      end

      time_end = Time.now.utc
      logger.info("[#{time_start.to_i}] end: #{time_end} | #{time_start} (#{time_end - time_start} seconds) [VideoJobs::TranscodeSchedulerJob]")
    rescue StandardError => e
      Airbrake.notify(e)
    end
  end
end
