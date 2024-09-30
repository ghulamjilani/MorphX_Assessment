# frozen_string_literal: true

json.cache! organization, expires_in: 1.day do
  json.id                   organization.id
  json.logo_url             organization.logo_url
  json.poster_url           organization.poster_url
  json.name                 organization.name
  json.user_id              organization.user_id
  json.slug                 organization.slug
  json.logo_link            organization.logo_link(current_user)
  json.relative_path        organization.relative_path
  json.views_count          organization.views_count
  json.channels_count       organization.channels_count
  json.creators_count       organization.creators_count
end
