# frozen_string_literal: true

envelope json, (@status || 200),
         (@channel_invited_presentership.pretty_errors if @channel_invited_presentership.errors.present?) do
  json.channel_invited_presentership do
    json.partial! 'channel_invited_presentership', channel_invited_presentership: @channel_invited_presentership

    json.channel do
      json.partial! 'api/v1/user/channels/channel_short', channel: @channel_invited_presentership.channel
    end
  end
end
