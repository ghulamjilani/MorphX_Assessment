# frozen_string_literal: true

envelope json do
  json.array! @invites do |invite|
    channel = invite.channel
    json.channel_info do
      json.id                         channel.id
      json.title                      CGI.unescapeHTML(strip_tags(channel.title))
      json.description                CGI.unescapeHTML(strip_tags(channel.description.to_s))
      json.url                        channel.absolute_path
      json.main_image                 channel.image_url
      json.images do
        json.array! channel.images do |image|
          json.url image.image_preview_url
        end
      end
    end
    json.organizer do
      json.user_id      channel.organizer.id
      json.display_name channel.organizer.display_name
      json.avatar_url   channel.organizer.avatar_url
    end
  end
end
