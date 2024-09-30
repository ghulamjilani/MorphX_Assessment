# frozen_string_literal: true

envelope json, (@status || 200), (@subscription.pretty_errors if @subscription.errors.present?) do
  json.partial! 'channel_subscription', subscription: @subscription
end
