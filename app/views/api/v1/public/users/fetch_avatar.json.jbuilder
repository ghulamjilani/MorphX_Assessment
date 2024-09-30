# frozen_string_literal: true

envelope json, (@status || 200) do
  json.url @url
end
