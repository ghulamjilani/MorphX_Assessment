# frozen_string_literal: true

envelope json do
  json.extract! resource, :id, :authentication_token, :timezone, :first_name, :last_name, :display_name, :email,
                :birthdate
  json.avatar_url asset_url resource.medium_avatar_url
  json.redirect_path @after_sign_in_path
  json.is_presenter current_user.presenter?
end
