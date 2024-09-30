# frozen_string_literal: true

json.extract! subscription, :id, :status, :created_at, :canceled_at, :current_period_end
json.plan do
  json.partial! 'api/v1/user/channel_subscriptions/plan', plan: subscription.stripe_plan
end

json.channel do
  json.extract! subscription.stripe_plan.channel, :id, :title, :relative_path, :logo_url
  json.cover_url subscription.stripe_plan.channel.image_url
end
