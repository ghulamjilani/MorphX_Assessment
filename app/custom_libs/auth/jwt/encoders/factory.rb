# frozen_string_literal: true

module Auth
  module Jwt
    module Encoders
      class Factory
        class << self
          def model_encoder_by_type(type)
            case type
            when Auth::Jwt::Types::USER_TOKEN, Auth::Jwt::Types::USER_TOKEN_REFRESH
              Auth::Jwt::Encoders::UserTokenEncoder
            when Auth::Jwt::Types::GUEST, Auth::Jwt::Types::GUEST_REFRESH
              Auth::Jwt::Encoders::GuestEncoder
            when Auth::Jwt::Types::ORGANIZATION
              Auth::Jwt::Encoders::OrganizationEncoder
            when Auth::Jwt::Types::USAGE
              Auth::Jwt::Encoders::UsageEncoder
            when Auth::Jwt::Types::ORGANIZATION_INTEGRATION
              Auth::Jwt::Encoders::Integrations::OrganizationEncoder
            else
              raise(ArgumentError, I18n.t('custom_libs.auth.jwt.encoders.factory.errors.unsupported_type', type: type))
            end
          end
        end
      end
    end
  end
end
