# frozen_string_literal: true

json.cache! post, expires_in: 1.day do
  json.id                   post.id
  json.title                post.title
  json.body_preview         post.body_preview
  json.slug                 post.slug
  json.relative_path        post.relative_path
  json.logo_url             post.logo_url
  json.cover_url            post.cover_url
  json.channel_id           post.channel_id
  json.organization_id      post.organization_id
  json.views_count          post.views_count
  json.comments_count       post.comments_count
  json.hide_author          post.hide_author
  json.status               post.status
  json.published_at         post.published_at
  json.likes_count          post.cached_votes_up
  json.edited_at            post.edited_at
  json.created_at           post.created_at
  json.updated_at           post.updated_at
end
