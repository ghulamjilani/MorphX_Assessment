# frozen_string_literal: true

module Api
  module V1
    module Auth
      # To generate refresh token
      class GuestsController < Api::V1::Auth::ApplicationController
        include ControllerConcerns::Shared::Authentication

        skip_before_action :authorization, unless: -> { action_name == 'create' && request.headers['Authorization'].present? }
        before_action :authorize_refresh_jwt, only: %i[update]

        def create
          if @current_guest.blank?
            visitor_id = params.require(:visitor_id)
            raise(ArgumentError, I18n.t('controllers.api.v1.auth.guests.errors.blank_visitor_id')) if visitor_id.blank?

            @current_guest = ::Guest.find_or_initialize_by(visitor_id: visitor_id)
          end

          @current_guest.update!(public_display_name: params.require(:public_display_name),
                                 secret: @current_guest.random_secret,
                                 ip_address: request_ip_address,
                                 user_agent: request.user_agent)
          encoded_jwt
          render :show
        end

        def update
          @current_guest.update(secret: @current_guest.random_secret)
          encoded_jwt
          render :show
        end

        private

        def authorize_refresh_jwt
          raise ArgumentError if jwt_from_header.blank?

          begin
            decoder = ::Auth::Jwt::Decoder.new(jwt_from_header)
            decoder.validate!
            @current_guest = decoder.model
          rescue StandardError => e
            notify_airbrake(e)
            @current_guest = nil

            raise AccessForbiddenError
          end
        end

        def encoded_jwt
          raise ArgumentError unless current_guest.is_a?(::Guest) && current_guest.persisted?

          encoder = ::Auth::Jwt::Encoder.new(type: ::Auth::Jwt::Types::GUEST, model: current_guest)
          @guest_jwt = encoder.jwt
          @refresh_jwt = encoder.refresh_jwt
          @jwt_exp = encoder.expires_at
          @refresh_jwt_exp = encoder.refresh_expires_at
          @status = 503 if @guest_jwt.blank?
        end
      end
    end
  end
end
