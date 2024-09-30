# frozen_string_literal: true

json.channel_category do
  json.partial! 'api/v1/public/channel_categories/channel_category_short', channel_category: channel_category
end
