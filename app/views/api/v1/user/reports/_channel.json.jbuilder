# frozen_string_literal: true

json.cache! ['app/views/api/v1/user/reports/_channel', channel_id], expires_in: 1.day do
  channel = Channel.find_by(id: channel_id)
  json.id channel&.id
  json.name channel&.title
  json.url channel&.absolute_path
end
