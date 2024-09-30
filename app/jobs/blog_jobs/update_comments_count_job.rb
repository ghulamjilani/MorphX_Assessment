# frozen_string_literal: true

module BlogJobs
  class UpdateCommentsCountJob < ApplicationJob
    sidekiq_options queue: :low

    def perform(*_args)
      Blog::Post.find_each(&:update_comments_count)
      Blog::Comment.find_each(&:update_comments_count)
    rescue StandardError => e
      Airbrake.notify(e)
    end
  end
end
