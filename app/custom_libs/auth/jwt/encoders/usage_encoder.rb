# frozen_string_literal: true

module Auth
  module Jwt
    module Encoders
      class UsageEncoder < Auth::Jwt::Encoders::ModelEncoderBase
        alias user model

        def jwt_secret
          ::Usage.config[:secret]
        end

        def payload
          {
            type: ::Auth::Jwt::Types::USAGE,
            platform: ::Usage.config[:platform],
            user_id: @model.try(:id),
            user_name: @model.try(:public_display_name),
            visitor_id: options[:visitor_id],
            exp: expires_at.to_i
          }
        end

        def encode_refresh
          nil
        end

        private

        def default_options
          {
            exp_minutes: Rails.application.credentials.backend.dig(:initialize, :security, :jwt, :usage, :access_exp_minutes),
            refresh_exp_minutes: 0
          }
        end
      end
    end
  end
end
