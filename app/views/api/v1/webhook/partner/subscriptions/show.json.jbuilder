# frozen_string_literal: true

envelope json, (@status || 200) do
  if @partner_subscription
    json.subscription do
      json.partial! 'api/v1/webhook/partner/subscriptions/subscription', partner_subscription: @partner_subscription
    end
  end
end
