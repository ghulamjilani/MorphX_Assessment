# frozen_string_literal: true

class Api::V1::Public::SearchController < Api::V1::ApplicationController
  skip_before_action :authorization, unless: -> { auth_header_present? }
  before_action :offset_limit

  def index
    if params[:searchable_type] == 'Session'
      if params[:created_after].present?
        params[:end_after] = params[:created_after]
        params[:created_after] = nil
      end
      if params[:created_before].present?
        params[:start_before] = params[:created_before]
        params[:created_before] = nil
      end
    end

    query = PgSearchDocument.where(nil).not_private
    if params[:query].present?
      query = if params[:search_by] == 'title'
                query.search_by_title(params[:query].prepare_for_search)
              else
                query.search(params[:query].prepare_for_search)
              end
    end

    query = query.multisearch_by_params(params)
    @documents = query.limit(@limit).offset(@offset).preload(
      :searchable,
      searchable_session: [:quality_of_content_average, { channel: :cover },
                           { room: { presenter_user: %i[wa_rtmp_free wa_main_free] } },
                           { presenter: { user: %i[image user_account] } }],
      searchable_channel: %i[category sessions cover organization]
    ).reject { |document| document.searchable.present? ? false : document.delete }
    @count = query.reorder('').distinct.count(:all)
  end

  private

  def offset_limit
    @limit = (params[:limit] || params[:per_page] || 15).to_i
    @limit = 15 if @limit < 1
    @offset = (params[:offset] || 0).to_i
    @page = (@offset + @limit) / @limit
  end

  def auth_header_present?
    request.headers['Authorization'].present?
  end
end
