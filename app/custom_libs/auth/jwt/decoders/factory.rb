# frozen_string_literal: true

module Auth
  module Jwt
    module Decoders
      class Factory
        class << self
          def model_decoder_by_type(type)
            case type
            when Auth::Jwt::Types::USER_TOKEN, Auth::Jwt::Types::USER_TOKEN_REFRESH
              Auth::Jwt::Decoders::UserTokenDecoder
            when Auth::Jwt::Types::GUEST, Auth::Jwt::Types::GUEST_REFRESH
              Auth::Jwt::Decoders::GuestDecoder
            when Auth::Jwt::Types::ORGANIZATION
              Auth::Jwt::Decoders::OrganizationDecoder
            when Auth::Jwt::Types::ORGANIZATION_INTEGRATION
              Auth::Jwt::Decoders::Integrations::OrganizationDecoder
            when Auth::Jwt::Types::USAGE
              Auth::Jwt::Decoders::UsageDecoder
            else
              raise(ArgumentError, I18n.t('custom_libs.auth.jwt.decoders.factory.errors.unsupported_type', type: type))
            end
          end
        end
      end
    end
  end
end
