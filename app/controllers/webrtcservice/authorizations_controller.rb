# frozen_string_literal: true

module Webrtcservice
  class AuthorizationsController < ApplicationController
    # before_action :authenticate_user!
    skip_before_action :gon_init
    skip_before_action :check_if_has_needed_cookie
    skip_before_action :extract_refc_from_url_into_cookie
    skip_before_action :check_if_referral_user
    skip_after_action :prepare_unobtrusive_flash
    skip_before_action :fetch_latest_notifications
    skip_before_action :fetch_upcoming_sessions_for_user
    skip_before_action :store_current_location
    skip_forgery_protection

    def create
      if (current_user && current_user.id == identity && params[:user_type] == 'User') || params[:user_type] == 'ChatMember'
        grant = Webrtcservice::JWT::AccessToken::ChatGrant.new
        grant.service_sid = ENV['webrtcservice_CHAT_SID']

        token = Webrtcservice::JWT::AccessToken.new(
          ENV['webrtcservice_ACCOUNT_SID'],
          ENV['webrtcservice_CHAT_API_KEY'],
          ENV['webrtcservice_CHAT_API_SECRET'],
          [grant],
          identity: identity
        )
        render json: { token: token.to_jwt }
      else
        render json: {}, status: 401
      end
    end

    private

    def identity
      params.permit(:identity)[:identity]
    end
  end
end
