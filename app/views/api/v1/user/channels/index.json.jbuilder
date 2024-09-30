# frozen_string_literal: true

envelope json do
  json.array! @channels do |channel|
    json.partial! 'channel', channel: channel

    json.images do
      json.array! channel.images do |image|
        json.url image.image_preview_url
      end
    end

    json.organizer do
      json.partial! '/api/v1/user/users/user_short', user: channel.organizer
    end

    json.can_subscribe current_user != channel.organizer
    json.following     current_user.fast_following?(channel)
  end
end
