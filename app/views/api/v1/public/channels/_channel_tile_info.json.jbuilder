# frozen_string_literal: true

json.cache! model, expires_in: 1.day do
  json.id                   model.id
  json.organization_id      model.organization_id
  json.title                model.title
  json.logo_url             model.logo_url
  json.description          model.description
  json.created_at           model.created_at.utc.to_fs(:rfc3339)
  json.updated_at           model.updated_at.utc.to_fs(:rfc3339)
  json.url                  spa_channel_url(model.slug)
  json.relative_path        spa_channel_path(model.slug)
  json.image_preview_url    model.image_preview_url
  json.cover_url            model.image_url # need cover url
  json.image_gallery_url    model.image_gallery_url
  json.show_on_home         model.show_on_home
  json.display_empty_blog   model.display_empty_blog
  json.past_sessions_count  model.past_sessions_count
  json.category_name model.category.name
end

if model.subscription.present?
  json.subscription_from model.subscription.plans.active.order(amount: :asc).first&.formatted_price
end

json.can_manage_documents current_ability.can?(:manage_documents, model)
json.can_add_documents current_ability.can?(:add_documents, model)
