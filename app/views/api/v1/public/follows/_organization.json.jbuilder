# frozen_string_literal: true

json.cache! model, expires_in: 1.day do
  json.organization do
    json.extract! model, :id, :name, :website_url, :relative_path,
                  :logo_url, :poster_url
  end
end
