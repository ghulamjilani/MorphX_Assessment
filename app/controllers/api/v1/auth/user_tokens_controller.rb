# frozen_string_literal: true

module Api
  module V1
    module Auth
      # To generate refresh token
      class UserTokensController < Api::V1::Auth::ApplicationController
        include ControllerConcerns::Shared::Authentication

        skip_before_action :authorization, only: [:show]
        before_action :current_token

        def show
          @current_user = @current_token.user
          @current_token.destroy
          @auth_user_token = ::Auth::UserToken.create!(user: @current_user,
                                                       device: request.user_agent,
                                                       ip: request.remote_ip)
          create_jwt_properties(type: ::Auth::Jwt::Types::USER_TOKEN, model: @auth_user_token)
          sign_in(:user, @current_user) unless signed_in_as_user?(@current_user)
        end

        private

        def current_token
          render_json 401 and return if jwt_from_header.blank?

          decoder = ::Auth::Jwt::Decoders::UserTokenDecoder.new(jwt_from_header)
          decoder.decode!

          render_json 401 and return unless decoder.type == ::Auth::Jwt::Types::USER_TOKEN_REFRESH

          @current_token = decoder.model
        rescue StandardError => error
          puts "ERROR: #{error.class}: #{error.message}"
          puts error.backtrace

          render_json 401 and return
        end
      end
    end
  end
end
