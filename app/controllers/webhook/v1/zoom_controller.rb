# frozen_string_literal: true

class Webhook::V1::ZoomController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def create
    Zoom::Webhook::Handler.handle(params: params)
    data = params.to_unsafe_h
    debug_logger('zoom-webhook', data) unless Rails.env.test?
    token = params[:payload][:plainToken]
    secret = Rails.application.credentials.backend.dig(:initialize, :zoom, :secret_token)
    digest = OpenSSL::Digest.new('sha256')
    render json: {
      plainToken: token,
      encryptedToken: OpenSSL::HMAC.hexdigest(digest, secret, token)
    }
  end

  def deauthorize
    data = params.to_unsafe_h
    debug_logger('zoom-webhook', data) unless Rails.env.test?
    head :ok
  end

  private

  def debug_logger(name, data = {})
    @custom_logger ||= Logger.new "#{Rails.root}/log/#{self.class.to_s.underscore.tr('/',
                                                                                     '_')}.#{Time.now.utc.strftime('%Y-%m')}.#{Rails.env}.#{`hostname`.to_s.strip}.log"
    @custom_logger.debug("[#{request&.remote_ip}]: #{name} | #{data}")
    puts "[#{self.class}][#{Time.now.utc}][#{request&.remote_ip}]: #{name} | #{data}"
  rescue StandardError => e
    Airbrake.notify(e)
  end
end
