# frozen_string_literal: true

json.cache! ['app/views/api/v1/public/calendar/users/_user', user], expires_in: 1.day do
  json.id                   user.id
  json.first_name           user.first_name
  json.last_name            user.last_name
  json.display_name         user.display_name
  json.avatar_url           user.avatar_url
end
