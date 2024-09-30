# frozen_string_literal: true

json.cache! ['app/views/api/v1/public/calendar/channels/_channel', channel], expires_in: 1.day do
  json.id                       channel.id
  json.title                    channel.title
  json.description              channel.description
  json.short_url                channel.short_url
  json.image_gallery_url        channel.image_gallery_url
end
