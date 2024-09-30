# frozen_string_literal: true

class BlogJobs::ClearImagesJob < ApplicationJob
  sidekiq_options queue: :low

  def perform(*_args)
    Blog::Image.where(blog_post_id: nil).where('updated_at < ?', 1.day.ago).delete_all
  rescue StandardError => e
    Airbrake.notify(e)
  end
end
