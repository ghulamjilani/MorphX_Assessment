# frozen_string_literal: true

class Spa::PricingController < Spa::ApplicationController
  def index
    return redirect_to root_path unless Rails.application.credentials.global.dig(:service_subscriptions, :enabled)
  end
end
