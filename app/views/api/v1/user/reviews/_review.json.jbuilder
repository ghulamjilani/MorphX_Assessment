# frozen_string_literal: true

json.id                             review.id
json.commentable_id                 review.commentable_id
json.commentable_type               review.commentable_type
json.user_id                        review.user_id
json.title                          review.title
json.overall_experience_comment     review.overall_experience_comment
json.visible                        review.visible
json.created_at                     review.created_at&.utc&.to_fs(:rfc3339)
json.updated_at                     review.updated_at&.utc&.to_fs(:rfc3339)
json.can_moderate                   current_ability.can?(:moderate, review)
