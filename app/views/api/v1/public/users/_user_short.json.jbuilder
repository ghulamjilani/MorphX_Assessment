# frozen_string_literal: true

json.cache! ['app/views/api/v1/public/users/_user_short', model], expires_in: 1.day do
  json.id                    model&.id
  json.public_display_name   model&.public_display_name
  json.short_url             model&.short_url
  json.avatar_url            model&.avatar_url
  json.slug                  model&.slug
  json.relative_path         model&.relative_path
  json.followers             model&.count_user_followers
  json.following             model&.following_users_count
  json.is_followed           current_user.present? && model.present? && current_user.following?(model)
end
json.has_booking_slots model&.has_booking_slots?
