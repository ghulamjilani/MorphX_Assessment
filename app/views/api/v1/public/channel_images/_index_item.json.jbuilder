# frozen_string_literal: true

json.channel_image do
  json.partial! 'api/v1/public/channel_images/channel_image_short', channel_image: channel_image
end
