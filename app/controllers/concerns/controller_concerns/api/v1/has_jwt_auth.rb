# frozen_string_literal: true

module ControllerConcerns
  module Api
    module V1
      module HasJwtAuth
        extend ActiveSupport::Concern

        def create_jwt_properties(type:, model:, options: {})
          jwt_encoder = ::Auth::Jwt::Encoder.new(type:, model:, options:)
          @jwt = jwt_encoder.jwt
          @jwt_expires_at = jwt_encoder.expires_at
          unless [::Auth::Jwt::Types::USAGE, ::Auth::Jwt::Types::ORGANIZATION].include?(type)
            @refresh_jwt = jwt_encoder.refresh_jwt
            @refresh_jwt_expires_at = jwt_encoder.refresh_expires_at
          end
        end
      end
    end
  end
end
