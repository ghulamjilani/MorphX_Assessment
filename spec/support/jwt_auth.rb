# frozen_string_literal: true

module JwtAuth
  class << self
    def guest(guest)
      Auth::Jwt::Encoder.new(type: Auth::Jwt::Types::GUEST, model: guest).jwt
    end

    def refresh_guest(guest)
      Auth::Jwt::Encoder.new(type: Auth::Jwt::Types::GUEST_REFRESH, model: guest).refresh_jwt
    end

    def user_token(user_token)
      Auth::Jwt::Encoder.new(type: Auth::Jwt::Types::USER_TOKEN, model: user_token).jwt
    end

    def user_token_refresh(user_token)
      Auth::Jwt::Encoder.new(type: Auth::Jwt::Types::USER_TOKEN, model: user_token).refresh_jwt
    end

    def user(user)
      user_token = FactoryBot.create(:auth_user_token, user: user)
      Auth::Jwt::Encoder.new(type: Auth::Jwt::Types::USER_TOKEN, model: user_token).jwt
    end

    def user_refresh(user)
      user_token = FactoryBot.create(:auth_user_token, user: user)
      Auth::Jwt::Encoder.new(type: Auth::Jwt::Types::USER_TOKEN, model: user_token).refresh_jwt
    end

    def organization(organization)
      organization.reload
      Auth::Jwt::Encoder.new(type: Auth::Jwt::Types::ORGANIZATION, model: organization).jwt
    end

    def organization_integration(organization)
      organization.reload
      Auth::Jwt::Encoder.new(type: Auth::Jwt::Types::ORGANIZATION_INTEGRATION, model: organization).jwt
    end
  end
end
