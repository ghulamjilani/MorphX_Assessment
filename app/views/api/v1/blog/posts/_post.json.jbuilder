# frozen_string_literal: true

json.cache! post, expires_in: 1.day do
  json.extract! post, :id, :organization_id, :channel_id, :user_id,
                :relative_path,
                :slug, :title, :body, :body_preview,
                :status, :comments_count,
                :logo_url, :cover_url,
                :tag_list, :hide_author,
                :views_count, :shares_count,
                :featured_link_preview_id
  json.likes_count      post.cached_votes_up
  json.published_at     post.published_at&.utc&.to_fs(:rfc3339)
  json.edited_at        post.edited_at&.utc&.to_fs(:rfc3339)
  json.created_at       post.created_at.utc.to_fs(:rfc3339)
  json.updated_at       post.updated_at.utc.to_fs(:rfc3339)
end

json.liked            current_user.present? ? current_user.liked?(post) : false
json.can_edit         current_ability.can?(:edit, post)
