# frozen_string_literal: true

json.channel do
  json.partial! 'api/v1/public/channels/channel_short', model: channel
  json.organization do
    json.partial! 'api/v1/public/organizations/organization_short', model: channel.organization
  end
end
json.channel_category do
  json.partial! 'api/v1/public/channel_categories/channel_category_short', channel_category: channel.category
end
json.user do
  json.partial! 'api/v1/public/users/user_short', model: channel.organizer
end
