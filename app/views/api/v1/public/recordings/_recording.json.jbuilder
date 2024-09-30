# frozen_string_literal: true

json.cache! model, expires_in: 1.day do
  json.id                                  model.id
  json.channel_id                          model.channel_id
  json.organization_id                     model.channel.organization_id
  json.title                               model.title
  json.description                         model.description
  json.purchase_price                      model.purchase_price
  json.private                             model.private
  json.short_url                           model.short_url
  json.referral_short_url                  model.referral_short_url
  json.status                              model.status
  json.width                               model.width
  json.height                              model.height
  json.duration                            model.duration
  json.tag_list                            model.tag_list
  json.views_count                         model.views_count
  json.unique_views_count                  model.unique_views_count
  json.created_at                          model.created_at.utc.to_fs(:rfc3339)
  json.updated_at                          model.updated_at.utc.to_fs(:rfc3339)
end

if current_ability.can?(:see_recording, model)
  json.url                                 model.url
else
  json.url                                 model.preview_url
end
