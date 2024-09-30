# frozen_string_literal: true

class IndexChannel < ApplicationJob
  def perform(channel_id)
    channel = Channel.find(channel_id)
    channel&.update_pg_search_document
  end
end
