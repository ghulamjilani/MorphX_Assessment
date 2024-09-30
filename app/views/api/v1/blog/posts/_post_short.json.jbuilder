# frozen_string_literal: true

json.cache! post, expires_in: 1.day do
  json.id                         post.id
  json.organization_id            post.organization_id
  json.channel_id                 post.channel_id
  json.relative_path              post.relative_path
  json.slug                       post.slug
  json.title                      post.title
  json.body                       post.body
  json.body_preview               post.body_preview
  json.status                     post.status
  json.comments_count             post.comments_count
  json.logo_url                   post.logo_url
  json.cover_url                  post.cover_url
  json.tag_list                   post.tag_list
  json.hide_author                post.hide_author
  json.views_count                post.views_count
  json.shares_count               post.shares_count
  json.featured_link_preview_id   post.featured_link_preview_id

  json.likes_count      post.cached_votes_up
  json.published_at     post.published_at&.utc&.to_fs(:rfc3339)
  json.updated_at       post.updated_at.utc.to_fs(:rfc3339)
end

if current_ability.can?(:edit, post)
  json.can_edit  true
  json.user_id   post.user_id
else
  json.can_edit  false
  json.user_id   post.hide_author ? nil : post.user_id
end

json.liked current_user.present? ? current_user.liked?(post) : false
