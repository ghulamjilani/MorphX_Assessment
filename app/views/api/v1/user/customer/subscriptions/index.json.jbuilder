# frozen_string_literal: true

envelope json do
  json.subscriptions do
    json.array! @subscriptions do |subscription|
      json.subscription do
        json.partial! 'subscription', subscription: subscription
      end

      json.channel_subscription do
        json.partial! 'channel_subscription', channel_subscription: subscription.channel_subscription
      end

      json.plan do
        json.partial! 'plan', plan: subscription.stripe_plan
      end

      json.channel do
        json.partial! '/api/v1/user/channels/channel_short', channel: subscription.channel
      end

      json.organization do
        json.partial! '/api/v1/public/organizations/organization_short', model: subscription.organization
      end
    end
  end
end
