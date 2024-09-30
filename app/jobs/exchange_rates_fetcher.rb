# frozen_string_literal: true

class ExchangeRatesFetcher < ApplicationJob
  def perform(*_args)
    Rails.logger.debug('purging exchange rates cache')

    Rails.cache.delete(EXCHANGE_CACHE_KEY)
    Money.default_bank.update_rates
    Money.default_bank.save_rates
  end
end
