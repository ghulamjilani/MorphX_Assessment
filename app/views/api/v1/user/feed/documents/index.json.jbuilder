# frozen_string_literal: true

envelope json do
  json.array! @documents do |document|
    json.partial! 'api/v1/user/documents/document', document: document
    json.channel do
      json.partial! '/api/v1/user/channels/channel_short', channel: document.channel

      json.raters_count document.channel.raters_count

      if document.channel.subscription.present?
        json.subscription do
          json.partial! '/api/v1/public/channel_subscription_plans/subscription', model: document.channel.subscription
          json.plans do
            json.array! document.channel.subscription.plans.active.order(amount: :asc) do |plan|
              json.partial! '/api/v1/public/channel_subscription_plans/plan', model: plan
            end
          end
        end
      end
    end
    json.organization do
      json.partial! '/api/v1/user/organizations/organization_short', organization: document.organization
    end
    json.presenter do
      json.partial! '/api/v1/user/users/user_short', user: document.user
    end
  end
end
