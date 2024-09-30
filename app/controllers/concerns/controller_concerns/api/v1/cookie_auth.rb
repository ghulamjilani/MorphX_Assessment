# frozen_string_literal: true

# Drop this file after full migrate to SPA
module ControllerConcerns
  module Api
    module V1
      # mixing jwt and cookie authentication
      module CookieAuth
        extend ActiveSupport::Concern

        AVAILABLE_TYPES = %w[organization user refresh].freeze

        included do
          after_action :mix_jwt_and_cookie
        end

        def mix_jwt_and_cookie
          if !defined?(current_user) || current_user.blank?
            clear_old_token
            return
          end

          jwt_decoder = ::Auth::Jwt::Decoders::UserTokenDecoder.new(cookies['_unite_session_jwt'])
          encoder_options = {}

          if jwt_decoder.valid? && jwt_decoder.user == current_user
            @user_token = jwt_decoder.model
            encoder_options[:expires_at] = jwt_decoder.expires_at
          end

          if @user_token.blank?
            clear_old_token
            @user_token = ::Auth::UserToken.create!(user: current_user, device: request.user_agent, ip: request.remote_ip)
          end

          jwt_encoder = ::Auth::Jwt::Encoders::UserTokenEncoder.new(@user_token, encoder_options)
          cookies['_unite_session_jwt'] = { value: jwt_encoder.jwt, expires: jwt_encoder.expires_at }
          cookies['_unite_session_jwt_refresh'] = { value: jwt_encoder.refresh_jwt, expires: jwt_encoder.refresh_expires_at }
        end

        def clear_old_token
          if cookies['_unite_session_jwt'].present?
            decoder = ::Auth::Jwt::Decoders::UserTokenDecoder.new(cookies['_unite_session_jwt'])
            decoder.model.try(:destroy)
          end

          cookies.delete('_unite_session_jwt')
          cookies.delete('_unite_session_jwt_refresh')
        end
      end
    end
  end
end
