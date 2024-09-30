# frozen_string_literal: true

class VideoOutdatedIndexSearch < ApplicationJob
  def perform(*_args)
    Video.where('solr_updated_at is null or (updated_at != solr_updated_at)').find_each do |video|
      video.update_pg_search_document
      video.update_columns(solr_updated_at: video.updated_at)
    end
  end
end
