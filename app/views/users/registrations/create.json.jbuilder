# frozen_string_literal: true

envelope json, (user.new_record? ? 400 : 201) do
  json.extract! user, :id, :authentication_token, :timezone, :first_name, :last_name, :display_name, :email, :birthdate
  json.avatar_url asset_url user.medium_avatar_url
  json.errors user.pretty_errors
  json.redirect_path redirect_path
end
