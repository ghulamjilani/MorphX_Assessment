# frozen_string_literal: true

envelope json, (@status || 200), (@channel_category.pretty_errors if @channel_category.errors.present?) do
  json.channel_category do
    json.partial! 'channel_category', channel_category: @channel_category
  end
end
