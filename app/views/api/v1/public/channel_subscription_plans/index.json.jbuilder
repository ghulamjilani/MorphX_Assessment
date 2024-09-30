# frozen_string_literal: true

envelope json do
  if @subscription.present?
    json.subscription do
      json.partial! 'subscription', model: @subscription
    end
  end
  if @plans.present?
    json.plans do
      json.array! @plans do |plan|
        json.partial! 'plan', model: plan
      end
    end
  end
end
