# frozen_string_literal: true

envelope json do
  json.array! @channels do |channel|
    json.partial! 'channel', channel: channel
  end
end
