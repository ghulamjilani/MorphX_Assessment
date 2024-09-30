# frozen_string_literal: true

json.cache! model, expires_in: 1.day do
  json.extract! model, :id, :name, :relative_path, :logo_url
end
