# frozen_string_literal: true
module Auth
  # For generate access and refresh tokens
  class UserToken < Auth::ApplicationRecord
    belongs_to :user, optional: false

    before_create :generate_token
    after_create :update_user_last_signin

    def jwt_secret
      raise 'Save before call' if new_record?

      Digest::MD5.hexdigest("#{user.encrypted_password}#{token}#{Rails.application.secret_key_base}")
    end

    private

    def generate_token
      self.token = SecureRandom.hex(128)
    end

    def update_user_last_signin
      user.update_columns(last_sign_in_at: Time.now)
    end
  end
end
