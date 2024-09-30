# frozen_string_literal: true

module Auth
  module Jwt
    module Encoders
      class OrganizationEncoder < Auth::Jwt::Encoders::ModelEncoderBase
        def payload
          {
            type: ::Auth::Jwt::Types::ORGANIZATION,
            id: @model.id,
            exp: @expires_at.to_i
          }
        end

        def encode_refresh
          nil
        end
      end
    end
  end
end
