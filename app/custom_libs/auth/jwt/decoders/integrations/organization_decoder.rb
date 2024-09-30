# frozen_string_literal: true

module Auth
  module Jwt
    module Decoders
      module Integrations
        class OrganizationDecoder < Auth::Jwt::Decoders::OrganizationDecoder
          def supported_jwt_types
            [Auth::Jwt::Types::ORGANIZATION_INTEGRATION]
          end

          def required_payload_keys
            %i[type id]
          end

          def expired?
            false
          end

          def jwt_secret
            @jwt_secret ||= @model.integration_jwt_secret
          end
        end
      end
    end
  end
end
