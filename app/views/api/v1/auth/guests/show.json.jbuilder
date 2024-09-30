# frozen_string_literal: true

envelope json, (@status || 200) do
  json.jwt_token @guest_jwt
  json.jwt_exp @jwt_exp&.utc&.to_fs(:rfc3339)
  json.jwt_token_refresh @refresh_jwt
  json.refresh_jwt_exp @refresh_jwt_exp&.utc&.to_fs(:rfc3339)

  json.guest do
    json.partial! 'api/v1/public/guests/guest', guest: @current_guest
  end
end
