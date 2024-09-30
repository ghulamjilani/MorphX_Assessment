# frozen_string_literal: true

module Auth
  module Jwt
    module Decoders
      class UserTokenDecoder < Auth::Jwt::Decoders::ModelDecoderBase
        attr_reader :user

        alias user_token model

        def decode
          return false unless valid?

          @model = ::Auth::UserToken.where(user_id: payload[:id]).find_by(id: payload[:tid])
          return false if @model.blank?

          @user = @model.user

          JWT.decode(jwt, @model.jwt_secret)
          @model
        rescue JWT::DecodeError, JWT::VerificationError, StandardError
          false
        end

        def decode!
          validate!
          @model = ::Auth::UserToken.where(user_id: payload[:id]).find(payload[:tid])
          JWT.decode(jwt, @model.jwt_secret)
          @user = @model.user
          @model
        end

        def required_payload_keys
          %i[type id tid exp]
        end

        def supported_jwt_types
          [Auth::Jwt::Types::USER_TOKEN, Auth::Jwt::Types::USER_TOKEN_REFRESH]
        end
      end
    end
  end
end
