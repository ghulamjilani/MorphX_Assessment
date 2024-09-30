# frozen_string_literal: true

json.video do
  json.partial! 'api/v1/public/videos/video_short', model: video
end
json.channel do
  json.partial! 'api/v1/public/channels/channel_tile_info', model: video.channel
end
json.room do
  json.partial! 'api/v1/public/rooms/room', model: video.room
end
json.abstract_session do
  json.partial! 'api/v1/public/sessions/session_short', model: video.room.abstract_session
end
json.presenter do
  json.partial! 'api/v1/public/presenters/presenter_short', model: video.room.abstract_session.presenter
end
json.presenter_user do
  json.partial! 'api/v1/public/users/user_short', model: video.room.abstract_session.presenter.user
end
json.organization do
  json.partial! 'api/v1/public/organizations/organization_short', model: video.room.abstract_session.organization
end
json.channel do
  json.cache! video.channel, expires_in: 1.day do
    json.id             video.channel.id
    json.relative_path  video.channel.relative_path
    json.slug           video.channel.slug
    json.user do
      json.id                 video.channel.organizer_user_id
      json.channel_user_url   spa_channel_url(video.channel.slug, user_modal: video.channel.organizer_user_id)
      json.slug               video.channel.organizer.slug
    end
    if video.channel.subscription.present?
      json.subscription do
        json.partial! '/api/v1/public/channel_subscription_plans/subscription', model: video.channel.subscription
        json.plans do
          json.array! video.channel.subscription.plans.active.order(amount: :asc) do |plan|
            json.partial! '/api/v1/public/channel_subscription_plans/plan', model: plan
          end
        end
      end
    end
  end
end
