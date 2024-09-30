# frozen_string_literal: true

class LinkPreviewJobs::ParseJob < ApplicationJob
  sidekiq_options queue: :critical

  def perform(id, try_count = 0)
    link_preview = LinkPreview.find_by(id: id)
    return if link_preview.blank?

    link_preview.send(:run_crawler, try_count)
  rescue StandardError => e
    LinkPreviewsChannel.broadcast 'link_parse_failed', { id: id, url: link_preview.url }
    Airbrake.notify("LinkPreviewJobs::ParseJob #{e.message}", parameters: {
                      id: id
                    })
    false
  end
end
