# frozen_string_literal: true

module Api
  module V1
    module Auth
      class RegistrationsController < Api::V1::Auth::ApplicationController
        skip_before_action :authorization, only: [:create]

        def create
          raise AccessForbiddenError unless Rails.application.credentials.global.dig(:sign_up, :enabled) || signup_token.present?

          @user = ::User.new(user_params)
          @user.before_create_generic_callbacks_without_skipping_validation
          if @user.save
            @current_user = @user
            @auth_user_token = ::Auth::UserToken.create!(user: @user, device: request.user_agent, ip: request.remote_ip)
            signup_token.used_by(@current_user) if signup_token.present?
            add_guest_membership(@user)

            vs_attrs = {
              user_id: @current_user.id,
              refc: cookies.permanent.signed[:refc],
              current: cookies[:sbjs_current],
              current_add: cookies[:sbjs_current_add],
              first: cookies[:sbjs_first],
              first_add: cookies[:sbjs_first_add],
              session: cookies[:sbjs_session],
              udata: cookies[:sbjs_udata],
              tzinfo: cookies[:tzinfo]
            }
            VisitorSource.track_visitor(cookies.permanent[:visitor_id], vs_attrs)

            sign_in(:user, @current_user)
            create_jwt_properties(type: ::Auth::Jwt::Types::USER_TOKEN, model: @auth_user_token)
            render :create, status: (@status || 200)
          else
            render_json(422, @user.full_errors, @user.pretty_errors)
          end
        end

        private

        def user_params
          params.require(:user).permit(:first_name, :last_name, :birthdate, :gender, :email, :password, :manually_set_timezone, user_account_attributes: %i[phone country]).tap do |attrs|
            attrs[:password_confirmation] = attrs[:password]
            attrs[:email] = attrs[:email].to_s.downcase
            attrs[:manually_set_timezone] = params[:user][:timezone]
          end
        end

        def signup_token
          return nil if params[:signup_token].blank?

          @signup_token ||= SignupToken.usable.find_by(params.require(:signup_token).permit(:token))
        end
      end
    end
  end
end
