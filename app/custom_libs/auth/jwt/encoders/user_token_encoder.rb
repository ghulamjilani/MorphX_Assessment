# frozen_string_literal: true

module Auth
  module Jwt
    module Encoders
      class UserTokenEncoder < Auth::Jwt::Encoders::ModelEncoderBase
        alias user_token model

        def user
          @model.user
        end

        def payload
          {
            type: 'user',
            id: @model.user.id,
            tid: @model.id,
            exp: @expires_at.to_i
          }
        end

        def refresh_payload
          {
            type: 'refresh',
            id: @model.user.id,
            tid: @model.id,
            exp: @refresh_expires_at.to_i
          }
        end
      end
    end
  end
end
