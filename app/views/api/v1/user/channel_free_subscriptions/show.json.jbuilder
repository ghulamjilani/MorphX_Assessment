# frozen_string_literal: true

envelope json, (@status || 200), (@free_subscription.pretty_errors if @free_subscription.errors.present?) do
  json.partial! 'channel_free_subscription', free_subscription: @free_subscription
end
