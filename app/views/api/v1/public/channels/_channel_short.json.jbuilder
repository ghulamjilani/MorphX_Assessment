# frozen_string_literal: true

json.cache! ['api_v1_public_channels_channel_short', model.cache_key], expires_in: 1.day do
  json.id                     model.id
  json.organization_id        model.organization_id
  json.status                 model.status
  json.title                  model.title
  json.description            model.description
  json.shares_count           model.shares_count
  json.past_sessions_count    model.past_sessions_count
  json.created_at             model.created_at.utc.to_fs(:rfc3339)
  json.updated_at             model.updated_at.utc.to_fs(:rfc3339)
  json.organizer_user_id      model.organizer_user_id
  json.raters_count           model.raters_count
  json.image_gallery_url      model.image_gallery_url
  json.relative_path          model.relative_path
  json.rating                 numeric_rating_for(model)
  json.category_name model.category.name
  if model.subscription.present?
    json.subscription do
      json.partial! '/api/v1/public/channel_subscription_plans/subscription', model: model.subscription
      json.plans do
        json.array! model.subscription.plans.active.order(amount: :asc) do |plan|
          json.partial! '/api/v1/public/channel_subscription_plans/plan', model: plan
        end
      end
    end
  end
end
