# frozen_string_literal: true

json.cache! image, expires_in: 1.day do
  json.extract! image, :id, :large_url, :organization_id, :blog_post_id
  json.created_at   image.created_at.utc.to_fs(:rfc3339)
  json.updated_at   image.updated_at.utc.to_fs(:rfc3339)
end
