# frozen_string_literal: true

envelope json, (@status || 200), nil, (@signup_token.pretty_errors if @signup_token.errors.present?) do
  json.signup_token do
    json.partial! 'signup_token', signup_token: @signup_token
  end
end
