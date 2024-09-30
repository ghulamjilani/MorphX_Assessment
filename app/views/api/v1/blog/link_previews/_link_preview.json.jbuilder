# frozen_string_literal: true

json.cache! link_preview, expires_in: 1.day do
  json.extract! link_preview, :id, :url, :title, :description, :image_url, :status
  json.created_at   link_preview.created_at.utc.to_fs(:rfc3339)
  json.updated_at   link_preview.updated_at.utc.to_fs(:rfc3339)
end
