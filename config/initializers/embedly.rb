# frozen_string_literal: true

Embedly.configure do |config|
  # prints debug messages to the logger
  config.debug = ENV['DEBUG'].present?

  # use a custom logger
  # config.logger = MyAwesomeLogger.new(STDERR)

  # disable typhoeus and use Net::HTTP instead
  # config.request_with :net_http
end

# require_dependency Rails.root.join('lib/immerss/embedly').to_s
