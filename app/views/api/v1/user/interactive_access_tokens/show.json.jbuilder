# frozen_string_literal: true

envelope json, (@status || 200),
         (@interactive_access_token.pretty_errors if @interactive_access_token.errors.present?) do
  json.interactive_access_token do
    json.partial! 'interactive_access_token', interactive_access_token: @interactive_access_token
  end
end
