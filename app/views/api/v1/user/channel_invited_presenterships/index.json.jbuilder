# frozen_string_literal: true

envelope json do
  json.channel_invited_presenterships do
    json.array! @channel_invited_presenterships do |channel_invited_presentership|
      json.channel_invited_presentership do
        json.partial! 'channel_invited_presentership', channel_invited_presentership: channel_invited_presentership

        json.channel do
          json.partial! 'api/v1/user/channels/channel_short', channel: channel_invited_presentership.channel
        end
      end
    end
  end
end
