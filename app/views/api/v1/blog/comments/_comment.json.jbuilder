# frozen_string_literal: true

json.cache! [comment], expires_in: 1.day do
  json.extract! comment, :id, :body, :user_id, :blog_post_id,
                :commentable_id, :commentable_type,
                :featured_link_preview_id, :comments_count
  json.edited_at        comment.edited_at&.utc&.to_fs(:rfc3339)
  json.created_at       comment.created_at.utc.to_fs(:rfc3339)
  json.updated_at       comment.updated_at.utc.to_fs(:rfc3339)
end
