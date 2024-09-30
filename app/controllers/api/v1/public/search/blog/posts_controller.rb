# frozen_string_literal: true

module Api
  module V1
    module Public
      module Search
        module Blog
          class PostsController < Api::V1::Public::Blog::PostsController
            def index
              relation = PgSearchDocument.where(searchable_type: 'Blog::Post').not_private
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
              @posts = ::Blog::Post.where(id: ids).sort_by { |o| ids.index(o.id) }
            end
          end
        end
      end
    end
  end
end
