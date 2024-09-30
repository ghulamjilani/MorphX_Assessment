# frozen_string_literal: true

json.user do
  json.partial! 'api/v1/public/users/user_short', model: user
end
