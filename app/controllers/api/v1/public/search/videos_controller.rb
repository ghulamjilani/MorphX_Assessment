# frozen_string_literal: true

class Api::V1::Public::Search::VideosController < Api::V1::Public::SearchController
  def index
    if params[:order_by].blank?
      params[:order_by] = 'start_at'
      params[:order] = 'desc' if params[:order].blank?
    end
    relation = PgSearchDocument.where(searchable_type: 'Video').not_private
    if params[:query].present?
      relation = if params[:search_by] == 'title'
                   relation.search_by_title(params[:query].prepare_for_search)
                 else
                   relation.search(params[:query].prepare_for_search)
                 end
    end
    relation = relation.multisearch_by_params(params)
    ids = relation.page(@page).per(@limit).pluck(:searchable_id)
    @count = relation.reorder('').distinct.count(:all)
    @videos = Video.where(id: ids).sort_by { |o| ids.index(o.id) }
  end
end
