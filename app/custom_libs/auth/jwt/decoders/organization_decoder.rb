# frozen_string_literal: true

module Auth
  module Jwt
    module Decoders
      class OrganizationDecoder < Auth::Jwt::Decoders::ModelDecoderBase
        alias organization model

        def klass
          ::Organization
        end

        def supported_jwt_types
          [Auth::Jwt::Types::ORGANIZATION]
        end
      end
    end
  end
end
