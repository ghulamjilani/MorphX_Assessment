# frozen_string_literal: true

json.cache! user, expires_in: 1.day do
  json.id                     user.id
  json.display_name           user.display_name
  json.public_display_name    user.public_display_name
  json.slug                   user.slug
  json.relative_path          spa_user_path(user.slug)
  json.absolute_url           spa_user_url(user.slug)
  json.avatar_url             user.avatar_url
  json.is_followed            current_user.present? && current_user.following?(user)
end
