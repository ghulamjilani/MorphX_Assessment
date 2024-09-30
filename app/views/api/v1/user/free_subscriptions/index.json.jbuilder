# frozen_string_literal: true

envelope json do
  json.array! @free_subscriptions do |free_subscription|
    json.partial! 'free_subscription', free_subscription: free_subscription
  end
end
