# frozen_string_literal: true

PayPal::SDK.configure(
  mode: ENV['PAYPAL_MODE'], # "sandbox" or "live"
  client_id: ENV['PAYPAL_CLIENT_ID'],
  client_secret: ENV['PAYPAL_CLIENT_SECRET'],
  ssl_options: ((Rails.env.production? || Rails.env.qa?) ? { ca_file: ENV['PAYPAL_CERT'] } : { ca_file: nil })
)
PayPal::SDK.logger = Logger.new "#{Rails.root}/log/debug_paypal_sdk.#{Rails.env}.#{`hostname`.to_s.strip}.log"
