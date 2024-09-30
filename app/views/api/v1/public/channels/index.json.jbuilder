# frozen_string_literal: true

envelope json do
  json.channels do
    json.array! @channels do |channel|
      json.partial! 'channel_tile_info', model: channel

      json.live_now channel.live_session_exists?

      json.images do
        json.array! channel.images do |image|
          json.url image.image_preview_url
        end
      end

      json.organizer do
        json.partial! '/api/v1/user/users/user_short', user: channel.organizer
      end

      json.organization do
        json.partial! '/api/v1/public/organizations/organization_short', model: channel.organization
      end

      if channel.subscription.present?
        json.subscription do
          json.partial! '/api/v1/public/channel_subscription_plans/subscription', model: channel.subscription
          json.plans do
            json.array! channel.subscription.plans.active.order(amount: :asc) do |plan|
              json.partial! '/api/v1/public/channel_subscription_plans/plan', model: plan
            end
          end
        end
      end
    end
  end
end
