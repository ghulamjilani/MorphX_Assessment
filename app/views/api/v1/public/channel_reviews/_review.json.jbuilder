# frozen_string_literal: true

json.extract! model, :id, :commentable_type, :commentable_id, :created_at, :stars_quantity
json.comment model.overall_experience_comment
json.commentable do
  json.extract! model.commentable, :id, :title, :relative_path
end
json.user do
  json.extract! model.user, :id, :public_display_name, :relative_path, :avatar_url
end
