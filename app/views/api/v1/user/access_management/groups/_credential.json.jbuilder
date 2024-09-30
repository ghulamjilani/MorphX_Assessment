# frozen_string_literal: true

json.extract! credential, :id, :description, :is_enabled, :is_for_channel, :is_master_only, :name
json.created_at credential.created_at.utc.to_fs(:rfc3339)
json.updated_at credential.updated_at.utc.to_fs(:rfc3339)
json.category do
  json.extract! credential.category, :id, :name
end
json.type do
  json.extract! credential.type, :id, :name
end
