# frozen_string_literal: true

envelope json do
  json.posts do
    json.array! @posts do |post|
      json.partial! 'index_item', post: post
    end
  end
end
