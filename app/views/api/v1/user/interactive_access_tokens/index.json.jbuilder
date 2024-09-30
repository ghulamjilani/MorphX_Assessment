# frozen_string_literal: true

envelope json, (@status || 200) do
  json.interactive_access_tokens do
    json.array! @interactive_access_tokens do |interactive_access_token|
      json.interactive_access_token do
        json.partial! 'interactive_access_token', interactive_access_token: interactive_access_token
      end
    end
  end
end
