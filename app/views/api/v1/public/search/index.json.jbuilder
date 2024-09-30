# frozen_string_literal: true

envelope json do
  json.documents do
    json.array! @documents do |document|
      json.document do
        json.partial! 'document', model: document
        json.promo_weight     document.searchable.current_promo_weight
        json.promo_start      document.promo_start
        json.promo_end        document.promo_end
      end
      json.searchable_model do
        view_path = document.searchable_type.underscore.pluralize # 'Blog::Post' -> 'blog/posts'
        entity = document.searchable_type.demodulize.underscore # 'Blog::Post' -> 'post'
        json.partial! "api/v1/public/#{view_path}/index_item", entity.to_sym => document.searchable
      end
    end
  end
end
