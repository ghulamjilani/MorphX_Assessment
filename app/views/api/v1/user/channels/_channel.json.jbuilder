# frozen_string_literal: true

json.cache! channel, expires_in: 1.day do
  json.id                         channel.id
  json.uuid                       channel.uuid
  json.organization_id            channel.organization_id
  json.category_id                channel.category_id
  json.status                     channel.status
  json.title                      channel.title
  json.logo_url                   channel.logo_url
  json.description                channel.description
  json.shares_count               channel.shares_count
  json.created_at                 channel.created_at.utc.to_fs(:rfc3339)
  json.updated_at                 channel.updated_at.utc.to_fs(:rfc3339)
  json.organizer_user_id          channel.organizer_user_id
  json.raters_count               channel.raters_count
  json.url                        spa_channel_url(channel.slug)
  json.relative_path              spa_channel_path(channel.slug)
  json.image_preview_url          channel.image_preview_url
  json.approved                   channel.approved?
  json.listed_at                  channel.listed_at
  json.short_url                  channel.short_url
  json.image_url                  channel.image_url
  json.fake                       channel.fake
  json.show_on_home               channel.show_on_home
  json.display_empty_blog         channel.display_empty_blog
  json.im_conversation_enabled    channel.im_conversation_enabled
  json.show_documents             channel.show_documents
end
