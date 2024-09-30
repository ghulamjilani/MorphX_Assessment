# frozen_string_literal: true

json.cache! list, expires_in: 1.day do
  json.id                   list.id
  json.organization_id      list.organization_id
  json.name                 list.name
  json.description          list.description
  json.logo                 list.logo
  json.url                  list.url
  json.selected             list.selected
  json.updated_at           list.updated_at.utc.to_fs(:rfc3339)
  json.created_at           list.created_at.utc.to_fs(:rfc3339)
end
