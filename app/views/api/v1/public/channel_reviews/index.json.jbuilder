# frozen_string_literal: true

envelope json do
  json.reviews do
    json.array! @reviews do |review|
      json.partial! 'api/v1/public/channel_reviews/review', model: review
    end
  end
end
