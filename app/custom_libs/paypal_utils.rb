# frozen_string_literal: true

class PaypalUtils
  # @return [String] - "VERIFIED" or "INVALID" - otherwise catch
  def self.validate_and_return(raw_post)
    uri = URI.parse('https://www.paypal.com/cgi-bin/webscr?cmd=_notify-validate')
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 60
    http.read_timeout = 60
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.use_ssl = true
    response = http.post(uri.request_uri, raw_post,
                         'Content-Length' => raw_post.size.to_s,
                         'User-Agent' => 'Immerss 1.0').body
  end

  def self.paypal_number(user_id:, abstract_session:)
    "#{abstract_session.class}/#{user_id}/#{abstract_session.id}"
    # AESCrypt.encrypt(raw_message, Immerss::Application.config.secret_key_base)
  end

  def self.decrypt_paypal_number(encrypted_data)

    # decrypted = begin
    #   AESCrypt.decrypt(encrypted_data, Immerss::Application.config.secret_key_base)
    # rescue StandardError
    #   nil
    #             end
    decrypted = encrypted_data
    return if decrypted.blank?

    splitted = decrypted.split('/')
    return if splitted.count < 2

    { model_class: splitted[0], user_id: splitted[1].to_i, model_id: splitted[2].to_i }
  end
end
