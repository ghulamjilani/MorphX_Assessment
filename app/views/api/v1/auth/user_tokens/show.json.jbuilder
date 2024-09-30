# frozen_string_literal: true

envelope json do
  json.jwt_token @jwt
  json.exp_time @jwt_expires_at.to_i
  json.jwt_token_refresh @refresh_jwt
  json.refresh_exp_time @refresh_jwt_expires_at.to_i

  if (organization = current_user.current_organization)
    json.current_organization do
      json.default_location organization_default_user_path(organization)
      json.membership_type  current_user.current_organization_membership_type
    end
  end
end
