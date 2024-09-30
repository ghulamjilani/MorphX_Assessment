# frozen_string_literal: true

class Api::V1::User::PaymentMethodsController < Api::V1::ApplicationController
  def index
    if current_user.has_payment_info?
      @cards = current_user.stripe_customer_sources
      @default_card = current_user.default_credit_card&.id
    else
      @cards = []
      @default_card = nil
    end
  end
end
