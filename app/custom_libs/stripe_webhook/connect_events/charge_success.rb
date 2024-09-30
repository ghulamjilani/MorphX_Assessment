# frozen_string_literal: true

class StripeWebhook::ConnectEvents::ChargeSuccess < StripeWebhook::Base
  @event_type = 'account.updated'

  def perform
    puts 'stub'
  end
end
