# frozen_string_literal: true

envelope json do
  if user
    json.extract! user, :id, :email, :first_name, :last_name, :display_name,
                  :authentication_token, :timezone, :birthdate
    json.avatar_url     asset_url user.medium_avatar_url
    json.is_presenter   user.presenter?
    json.jwt_token @jwt
    json.exp_time @jwt_expires_at.to_i
    json.jwt_token_refresh @refresh_jwt
    json.refresh_exp_time @refresh_jwt_expires_at.to_i
    json.can_become_a_creator ::NonAdminCrudAbility.new(user).can?(:become_a_creator, user)
  end
  json.redirect_path    redirect_path
  json.flash            flash.to_hash
end
