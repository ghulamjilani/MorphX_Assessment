# frozen_string_literal: true

class Stripe::WebhooksController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def general
    StripeWebhook::General.handle(params: params)
    head :ok
  end

  def connect
    result = StripeWebhook::Connect.handle(params: params)
    puts result
    head :ok
  end
end
