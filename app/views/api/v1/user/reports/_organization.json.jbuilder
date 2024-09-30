# frozen_string_literal: true

json.cache! ['app/views/api/v1/user/reports/_organization', organization_id], expires_in: 1.day do
  organization = Organization.find_by(id: organization_id)
  json.id organization&.id
  json.name organization&.name
  json.url organization&.absolute_path
end
