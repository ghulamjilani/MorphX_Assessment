# frozen_string_literal: true

json.extract!       group, :id, :code, :description, :system, :enabled, :name, :color
json.is_for_channel group.credentials.any?(&:is_for_channel?)
json.created_at     group.created_at.utc.to_fs(:rfc3339)
json.updated_at     group.updated_at.utc.to_fs(:rfc3339)

json.credentials    group.credentials.each do |credo|
  json.partial! 'credential', credential: credo
end
