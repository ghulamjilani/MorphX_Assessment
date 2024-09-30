# frozen_string_literal: true

envelope json, (@status || 200), nil, (@user.pretty_errors if @user.errors.present?) do
  if current_user.present?
    json.jwt_token @jwt
    json.exp_time @jwt_expires_at.to_i
    json.jwt_token_refresh @refresh_jwt
    json.refresh_exp_time @refresh_jwt_expires_at.to_i
    json.user do
      json.partial! 'api/v1/user/users/user', user: current_user
      # for Victor until he stop to use old api
      json.authentication_token current_user.authentication_token

      if (organization = current_user.current_organization)
        json.current_organization do
          json.default_location organization_default_user_path(organization)
          json.membership_type  current_user.current_organization_membership_type
        end
      end
    end
  end
end
