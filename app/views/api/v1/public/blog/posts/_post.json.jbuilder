# frozen_string_literal: true

json.cache! post, expires_in: 1.day do
  json.id                           post.id
  json.title                        post.title
  json.slug                         post.slug
  json.body                         post.body
  json.body_preview                 post.body_preview
  json.relative_path                post.relative_path
  json.logo_url                     post.logo_url
  json.cover_url                    post.cover_url
  json.channel_id                   post.channel_id
  json.organization_id              post.organization_id
  json.views_count                  post.views_count
  json.comments_count               post.comments_count
  json.likes_count                  post.cached_votes_up
  json.shares_count                 post.shares_count
  json.tag_list                     post.tag_list
  json.featured_link_preview_id     post.featured_link_preview_id
  json.hide_author                  post.hide_author
  json.status                       post.status
  json.published_at                 post.published_at
end
