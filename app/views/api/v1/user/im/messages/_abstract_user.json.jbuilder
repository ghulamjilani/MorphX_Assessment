# frozen_string_literal: true

json.cache! abstract_user, expires_in: 1.day do
  json.id                     abstract_user.id
  json.type                   abstract_user.class.name
  json.public_display_name    abstract_user.public_display_name
  json.slug                   abstract_user&.slug
  json.relative_path          abstract_user.is_a?(User) ? spa_user_path(abstract_user.slug) : nil
  json.absolute_url           abstract_user.is_a?(User) ? spa_user_url(abstract_user.slug) : nil
  json.avatar_url             abstract_user.avatar_url
end
