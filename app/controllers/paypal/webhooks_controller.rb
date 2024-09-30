# frozen_string_literal: true

class Paypal::WebhooksController < ActionController::Base
  def create
    puts params
    head :not_found
  end
end
