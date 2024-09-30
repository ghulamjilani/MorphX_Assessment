# frozen_string_literal: true

envelope json do
  json.array! @subscriptions do |subscription|
    json.partial! 'service_subscription', subscription: subscription
  end
end
