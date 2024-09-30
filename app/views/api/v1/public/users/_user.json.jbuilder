# frozen_string_literal: true

json.cache! model, expires_in: 1.day do
  json.id                  model.id
  json.display_name        model.display_name
  json.public_display_name model.public_display_name
  json.short_url           model.short_url
  json.referral_short_url  model.referral_short_url
  json.avatar_url          model.avatar_url
  json.created_at          model.created_at.utc.to_fs(:rfc3339)
  json.relative_path       model.relative_path
end
