# frozen_string_literal: true

class LinkPreviewsChannel < ApplicationCable::Channel
  EVENTS = {
    link_parse_failed: 'link parse for link preview failed',
    link_parsed: 'link for link preview successfully parsed'
  }.freeze

  def subscribed
    stream_from 'link_previews_channel'

    link_preview = LinkPreview.find_by(id: params[:data])

    if link_preview.present?
      stream_for link_preview
    end
  end

  def unsubscribed
  end
end
