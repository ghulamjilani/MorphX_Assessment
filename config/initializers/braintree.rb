# frozen_string_literal: true

if !Rails.env.test? && !ENV['BRAINTREE_ENVIRONMENT'].nil? # because of http://stackoverflow.com/a/18192417
  Braintree::Configuration.environment = ENV['BRAINTREE_ENVIRONMENT'].to_sym
  Braintree::Configuration.merchant_id = ENV['BRAINTREE_MERCHANT_ID']
  Braintree::Configuration.public_key  = ENV['BRAINTREE_PUBLIC_KEY']
  Braintree::Configuration.private_key = ENV['BRAINTREE_PRIVATE_KEY']

  Braintree::Configuration.logger = Logger.new "#{Rails.root}/log/debug_braintree.#{Rails.env}.#{`hostname`.to_s.strip}.log"
  Braintree::Configuration.logger.level = Logger::DEBUG
end
