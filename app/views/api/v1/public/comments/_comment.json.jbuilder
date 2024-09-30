# frozen_string_literal: true

json.id               comment.id
json.commentable_id   comment.commentable_id
json.commentable_type comment.commentable_type
json.user_id          comment.user_id
json.body             comment.body
json.edited_at        comment.edited_at&.utc&.to_fs(:rfc3339)
json.created_at       comment.created_at.utc.to_fs(:rfc3339)
json.updated_at       comment.updated_at.utc.to_fs(:rfc3339)
json.comments_count   comment.comments_count
json.visible          comment.visible
json.can_edit         current_ability.can?(:edit, comment)
json.can_destroy      current_ability.can?(:destroy, comment)
json.can_moderate     current_ability.can?(:moderate, comment)
