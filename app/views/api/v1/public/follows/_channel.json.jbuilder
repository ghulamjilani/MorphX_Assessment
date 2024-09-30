# frozen_string_literal: true

json.cache! model, expires_in: 1.day do
  json.channel do
    json.extract! model, :id, :title, :short_url, :relative_path,
                  :logo_url, :image_gallery_url
  end
end
