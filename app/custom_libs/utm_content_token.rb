# frozen_string_literal: true

class UtmContentToken
  def initialize(token)
    @token = token
  end

  def self.for_user_id_and_email(user_id, email)
    Base64.urlsafe_encode64 "#{user_id}|#{email}"
  end

  # @return [Integer]
  def user_id
    decode if @decoded.blank?

    @decoded[:user_id]
  end

  # @return [String]
  def email
    decode if @decoded.blank?

    @decoded[:email]
  end

  def valid?
    decode
    true
  rescue ArgumentError => e
    false
  end

  private

  def decode
    result = Base64.urlsafe_decode64 @token
    values = result.split '|'
    @decoded = { user_id: values[0].to_i, email: values[1] } # if values.length == 2
  end
end
