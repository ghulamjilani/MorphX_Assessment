# frozen_string_literal: true

envelope json, (@status || 200), (@user.pretty_errors if @user.errors.present?) do
  json.extract! @user, :id, :public_display_name, :avatar_url, :relative_path
  json.bio @bio
  json.followers_count @user.count_user_followers
  json.following_count @user.following_users_count
  json.following @following
  json.has_booking_slots @user.has_booking_slots?
  json.booking_available @user.booking_available?

  json.channels_as_owner do
    json.array! @owned_channels do |channel|
      json.partial! 'api/v1/public/channels/channel', model: channel
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
  json.channels_as_invited_presenter do
    json.array! @invited_channels do |channel|
      json.partial! 'api/v1/public/channels/channel', model: channel
      json.organization do
        json.partial! '/api/v1/public/organizations/organization_short', model: channel.organization
      end
      json.organizer do
        json.partial! '/api/v1/user/users/user_short', user: channel.organizer
      end
    end
  end
  json.social_links do
    json.array! @social_links do |social_link|
      json.partial! 'api/v1/public/social_links/social_link', social_link: social_link
    end
  end
end
