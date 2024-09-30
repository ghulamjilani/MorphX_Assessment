# frozen_string_literal: true

module Auth
  module Jwt
    module Decoders
      class UsageDecoder < Auth::Jwt::Decoders::ModelDecoderBase
        alias user model

        validate :validate_platform

        def decode
          return false unless valid?

          JWT.decode(jwt, ::Usage.config[:secret])
          @model = User.find_by(id: payload[:user_id])
          @model
        rescue JWT::DecodeError, JWT::VerificationError, StandardError
          false
        end

        def decode!
          validate!

          JWT.decode(jwt, ::Usage.config[:secret])
          @model = User.find(payload[:user_id]) if payload[:user_id]
          @model
        end

        def supported_jwt_types
          [Auth::Jwt::Types::USAGE]
        end

        def required_payload_keys
          %i[type platform exp]
        end

        private

        def validate_platform
          if payload[:platform] != ::Usage.config[:platform]
            errors.add(:platform, I18n.t('custom_libs.auth.jwt.decoder.errors.payload.wrong_platform', platform: payload[:platform], class: self.class.name))
          end

          errors.where(:platform).blank?
        end
      end
    end
  end
end
