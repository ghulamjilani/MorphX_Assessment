# frozen_string_literal: true

module Auth
  module Jwt
    module Encoders
      class GuestEncoder < Auth::Jwt::Encoders::ModelEncoderBase
        alias guest model

        def payload
          {
            type: ::Auth::Jwt::Types::GUEST,
            id: @model.id,
            exp: @expires_at.to_i
          }
        end

        def refresh_payload
          {
            type: ::Auth::Jwt::Types::GUEST_REFRESH,
            id: @model.id,
            exp: @refresh_expires_at.to_i
          }
        end

        private

        def default_options
          {
            exp_minutes: Rails.application.credentials.backend.dig(:initialize, :security, :jwt, :guest, :access_exp_minutes),
            refresh_exp_minutes: Rails.application.credentials.backend.dig(:initialize, :security, :jwt, :guest, :refresh_exp_minutes)
          }
        end
      end
    end
  end
end
