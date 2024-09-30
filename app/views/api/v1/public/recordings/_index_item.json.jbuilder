# frozen_string_literal: true

json.recording do
  json.partial! 'api/v1/public/recordings/recording_short', model: recording
end
json.channel do
  json.partial! 'api/v1/public/channels/channel_short', model: recording.channel
  if recording.channel.subscription.present?
    json.subscription do
      json.cache! recording.channel.subscription, expires_in: 1.day do
        json.partial! '/api/v1/public/channel_subscription_plans/subscription', model: recording.channel.subscription
        json.plans do
          json.array! recording.channel.subscription.plans.active.order(amount: :asc) do |plan|
            json.partial! '/api/v1/public/channel_subscription_plans/plan', model: plan
          end
        end
      end
    end
  end
end
json.organizer do
  json.partial! 'api/v1/public/users/user_short', model: recording.organizer
end
json.organization do
  json.partial! 'api/v1/public/organizations/organization_short', model: recording.channel.organization
end
