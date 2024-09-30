# frozen_string_literal: true

envelope json do
  json.videos do
    json.array! @videos do |video|
      json.partial! 'api/v1/public/videos/index_item', video: video
    end
  end
end
