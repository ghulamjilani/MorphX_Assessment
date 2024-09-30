# frozen_string_literal: true

json.cache! model, expires_in: 1.day do
  json.id                 model.id
  json.duration           model.actual_duration
  json.room_id            model.room_id
  json.channel_id         model.channel.id
  json.user_id            model.user_id
  json.status             model.status
  json.short_url          model.short_url
  json.referral_short_url model.referral_short_url
  json.title              model.title
  json.width              model.width
  json.height             model.height
  json.description        model.description
  json.relative_path      model.relative_path
  json.views_count        model.views_count
  json.unique_views_count model.unique_views_count
end
