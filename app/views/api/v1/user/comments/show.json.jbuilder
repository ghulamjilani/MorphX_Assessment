# frozen_string_literal: true

envelope json do
  json.comment do
    json.partial! 'api/v1/public/comments/comment', comment: @comment
    json.user do
      json.partial! 'api/v1/public/users/user_short', model: @comment.user
    end
    json.commentable do
      json.partial! 'api/v1/public/comments/commentable', commentable: @comment.commentable
    end
  end
end
