# frozen_string_literal: true

envelope json, (@status || 200), (@channel_image.pretty_errors if @channel_image.errors.present?) do
  json.channel_image do
    json.partial! 'channel_image', channel_image: @channel_image
  end
end
