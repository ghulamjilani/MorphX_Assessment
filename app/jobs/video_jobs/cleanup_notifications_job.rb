# frozen_string_literal: true

module VideoJobs
  class CleanupNotificationsJob < ApplicationJob
    def perform(*_args)
      notify_days = if Rails.env.production?
                      [1, 10].map { |i| Video::DELETE_AFTER_DAYS - i }
                    else
                      [1, 2].map { |i| Video::DELETE_AFTER_DAYS - i }
                    end
      notify_days.each do |i|
        Video.joins(room: :session)
             .where.not(sessions: { recorded_purchase_price: nil })
             .group(:user_id).select('array_agg(videos.id) as video_ids, user_id')
             .where(deleted_at: nil,
                    status: Video::Statuses::ORIGINAL_VERIFIED,
                    created_at: i.days.ago.all_day).each do |video|
          next unless video.user_id

          VideoMailer.cleanup_notification(
            user_id: video.user_id,
            video_ids: video.video_ids,
            time_interval: i
          ).deliver_later
        end
      end
    end
  end
end
