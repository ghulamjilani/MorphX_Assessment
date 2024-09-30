# frozen_string_literal: true

json.organization do
  json.partial! 'api/v1/public/organizations/organization', model: organization
end
json.user do
  json.partial! 'api/v1/public/users/user_short', model: organization.user
end
