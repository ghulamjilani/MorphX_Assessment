# frozen_string_literal: true

envelope json do
  json.channels do
    json.array! @channels do |channel|
      json.partial! 'api/v1/public/channels/index_item', channel: channel
      json.organization do
        json.partial! '/api/v1/public/organizations/organization_short', model: channel.organization
      end
    end
  end
end
