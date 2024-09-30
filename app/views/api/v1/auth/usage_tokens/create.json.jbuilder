# frozen_string_literal: true

envelope json, (@status || 200), nil, @usage_jwt_errors do
  json.usage_jwt @usage_jwt
  json.usage_jwt_exp @usage_jwt_exp&.utc&.to_fs(:rfc3339)
  json.usage_user_messages_url @usage_user_messages_url
end
