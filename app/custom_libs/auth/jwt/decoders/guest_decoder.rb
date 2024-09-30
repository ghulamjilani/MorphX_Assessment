# frozen_string_literal: true

module Auth
  module Jwt
    module Decoders
      class GuestDecoder < Auth::Jwt::Decoders::ModelDecoderBase
        alias guest model

        def klass
          ::Guest
        end

        def supported_jwt_types
          [Auth::Jwt::Types::GUEST, Auth::Jwt::Types::GUEST_REFRESH]
        end
      end
    end
  end
end
