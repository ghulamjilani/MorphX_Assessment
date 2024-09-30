# frozen_string_literal: true

module MoneyHelper
  # @return[String] examples:
  #                "20.13 ₴"
  #                "$5.25"
  #                "-$15.33"
  def as_currency(usd_amount, current_user = nil)
    exception_cb = proc do |_exception|
      Money.default_bank.update_rates
      Money.default_bank.save_rates
    end
    Retryable.retryable(tries: 2, on: Money::Bank::UnknownRate, exception_cb: exception_cb) do
      _currency = current_user ? current_user.currency : 'USD'
      Money.new(usd_amount.to_f * 100).exchange_to(_currency).format(sign_before_symbol: true)
    end
  rescue StandardError
    Money.new(usd_amount.to_f * 100).format(sign_before_symbol: true)
  end

  def openexchange_currencies
    return { 'USD' => 'United States Dollar' } if Rails.env.production?

    {
      'AUD' => 'Australian Dollar',
      'CAD' => 'Canadian Dollar',
      'CNY' => 'Chinese Yuan',
      'EUR' => 'Euro',
      'GBP' => 'British Pound Sterling',
      'INR' => 'Indian Rupee',
      'JPY' => 'Japanese Yen',
      'RUB' => 'Russian Ruble',
      'USD' => 'United States Dollar'
    }
  end
end
