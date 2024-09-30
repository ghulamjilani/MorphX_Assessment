# frozen_string_literal: true

envelope json, (@status || 200) do
  json.partial! 'api/v1/public/guests/guest', guest: @guest
end
