# frozen_string_literal: true

envelope json do
  json.free_subscriptions do
    json.array! @free_subscriptions do |free_subscription|
      json.free_subscription do
        json.partial! 'free_subscription', free_subscription: free_subscription
      end

      json.free_plan do
        json.partial! 'free_plan', free_plan: free_subscription.free_plan
      end

      json.channel do
        json.partial! '/api/v1/user/channels/channel_short', channel: free_subscription.channel
      end

      json.organization do
        json.partial! '/api/v1/public/organizations/organization_short', model: free_subscription.organization
      end
    end
  end
end
