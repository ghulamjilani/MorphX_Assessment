# frozen_string_literal: true

class VideoJobs::Cleanup < ApplicationJob
  def perform
    now = Time.now
    Video.where('created_at < ?', now - Video::DELETE_AFTER_DAYS.days)
         .where(status: Video::Statuses::ORIGINAL_VERIFIED, deleted_at: nil)
         .find_each { |v| v.touch :deleted_at }
  end
end
