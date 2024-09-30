# frozen_string_literal: true

class Api::V1::Public::Search::SessionsController < Api::V1::Public::SearchController
  def index
    if params[:order_by].blank?
      params[:order_by] = 'start_at'
      params[:order] = 'asc' if params[:order].blank?
    end
    relation = PgSearchDocument.where(searchable_type: 'Session').not_private
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
    @sessions = Session.where(id: ids).order(Arel.sql("position(id::text in '#{ids.join(',')}')"))
  end
end
