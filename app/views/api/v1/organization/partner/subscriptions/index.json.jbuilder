# frozen_string_literal: true

envelope json do
  json.partner_subscriptions do
    json.array! @partner_subscriptions do |partner_subscription|
      json.partner_subscription do
        json.partial! 'partner_subscription', partner_subscription: partner_subscription
      end
    end
  end
end
