# frozen_string_literal: true

class IndexVideo < ApplicationJob
  def perform(video_id)
    video = Video.find(video_id)
    if video
      video.update_pg_search_document
      video.update_columns(solr_updated_at: video.updated_at)
    end
  end
end
