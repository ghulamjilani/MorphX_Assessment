# frozen_string_literal: true

envelope json, (@status || 200), nil, (@signup_token.pretty_errors if @signup_token.errors.present?) do
  json.signup_token do
    json.partial! 'signup_token', signup_token: @signup_token
  end
  json.user do
    json.partial! 'api/v1/user/users/user', user: current_user
  end
end
