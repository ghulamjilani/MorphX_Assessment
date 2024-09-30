# frozen_string_literal: true

json.cache! ['app/views/api/v1/public/calendar/recordings/_recording', recording], expires_in: 1.day do
  json.id                  recording.id
  json.channel_id          recording.channel_id
  json.title               recording.title
  json.description         recording.description
  json.url                 recording.url
end
