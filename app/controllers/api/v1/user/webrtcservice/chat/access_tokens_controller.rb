# frozen_string_literal: true

class Api::V1::User::Webrtcservice::Chat::AccessTokensController < Api::V1::User::Webrtcservice::ApplicationController
  skip_before_action :authorization, unless: -> { request.headers['Authorization'].present? }
  skip_before_action :authorization_only_for_user, only: [:create]

  def create
    if (params[:user_type] == 'User' && current_user&.id.to_s == identity.to_s) \
       || params[:user_type] == 'ChatMember'
      render_json(200, { token: ::Webrtcservice::Chat::Token.access_token(identity) })
    else
      render_json(401, 'Access denied')
    end
  end

  private

  def identity
    params.require(:identity)
  end
end
