# frozen_string_literal: true

json.session do
  json.partial! 'api/v1/public/sessions/session_short', model: session
end
json.presenter do
  json.partial! 'api/v1/public/presenters/presenter_short', model: session.presenter
end
json.presenter_user do
  json.partial! 'api/v1/public/users/user_short', model: session.presenter.user
end
json.organization do
  json.partial! 'api/v1/public/organizations/organization_short', model: session.organization
end
json.channel do
  json.cache! session.channel, expires_in: 1.day do
    json.id             session.channel.id
    json.relative_path  session.channel.relative_path
    json.slug           session.channel.slug
    json.user do
      json.id                 session.channel.organizer_user_id
      json.channel_user_url   spa_channel_url(session.channel.slug, user_modal: session.channel.organizer_user_id)
      json.slug               session.channel.organizer.slug
    end
    if session.channel.subscription.present?
      json.subscription do
        json.partial! '/api/v1/public/channel_subscription_plans/subscription', model: session.channel.subscription
        json.plans do
          json.array! session.channel.subscription.plans.active.order(amount: :asc) do |plan|
            json.partial! '/api/v1/public/channel_subscription_plans/plan', model: plan
          end
        end
      end
    end
  end
end
