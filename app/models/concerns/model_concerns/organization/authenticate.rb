# frozen_string_literal: true

module ModelConcerns::Organization::Authenticate
  extend ActiveSupport::Concern

  def secret_token
    @secret_token ||= secret_token_hash.present? ? BCrypt::Password.new(secret_token_hash) : ''
  end

  def secret_token=(new_secret_token)
    @secret_token = BCrypt::Password.create(new_secret_token)
    self.secret_token_hash = @secret_token
  end

  def token_is_correct?(secret_token)
    self.secret_token == secret_token
  end
end
