# frozen_string_literal: true

envelope json do
  json.jwt_token @jwt
  json.exp_time @jwt_expires_at.to_i
  json.organization do
    json.partial! 'api/v1/organizations/organization', organization: @organization
  end
end
