# frozen_string_literal: true

json.cache! ['app/views/api/v1/public/calendar/videos/_video', video], expires_in: 1.day do
  json.id                                                 video.id
  json.channel_id                                         video.session.channel_id
  json.short_url                                          video.short_url
  json.description                                        video.description
  json.relative_path                                      video.relative_path
end
