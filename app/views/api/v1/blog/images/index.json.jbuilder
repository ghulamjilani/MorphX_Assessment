# frozen_string_literal: true

envelope json do
  json.images do
    json.array! @images do |image|
      json.image do
        json.partial! 'image', image: image
      end
    end
  end
end
