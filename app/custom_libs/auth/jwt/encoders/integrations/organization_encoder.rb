# frozen_string_literal: true

module Auth
  module Jwt
    module Encoders
      module Integrations
        class OrganizationEncoder < Auth::Jwt::Encoders::OrganizationEncoder
          def payload
            {
              type: ::Auth::Jwt::Types::ORGANIZATION_INTEGRATION,
              id: @model.id
            }
          end

          def jwt_secret
            @model.integration_jwt_secret
          end
        end
      end
    end
  end
end
