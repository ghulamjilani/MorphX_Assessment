# frozen_string_literal: true

require 'money/bank/open_exchange_rates_bank'
moe = Money::Bank::OpenExchangeRatesBank.new
moe.app_id = 'd27c055b566941999657c12c9c55c14d'
EXCHANGE_CACHE_KEY = 'exchangerates'

# # use https to fetch rates from Open Exchange Rates
# # disabled by default to support free-tier users
# # see https://openexchangerates.org/documentation#https
# moe.secure_connection = false

moe.cache = proc do |v|
  if v
    Rails.logger.debug('writing exchange rates to cache')
    Rails.cache.write(EXCHANGE_CACHE_KEY, v)
  else
    Rails.logger.debug('reading exchange rates from cache')
    Rails.cache.read(EXCHANGE_CACHE_KEY)
  end
end

Money.default_bank = moe
Money.locale_backend = nil
