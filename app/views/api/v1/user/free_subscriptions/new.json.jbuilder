# frozen_string_literal: true

envelope json do
  json.array! @channels do |channel|
    json.partial! 'api/v1/public/channels/channel', model: channel
  end
end
