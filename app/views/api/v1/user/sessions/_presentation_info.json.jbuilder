# frozen_string_literal: true

json.presentation_id          session.channel.id
json.presentation_title       CGI.unescapeHTML(session.channel.title)
json.main_image               session.medium_cover_url
json.images do
  json.array! session.channel.images do |image|
    json.url image.image_preview_url
  end
end
