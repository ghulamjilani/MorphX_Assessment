# frozen_string_literal: true

Rails.configuration.stripe = {
  publishable_key: Rails.application.credentials.global.dig(:stripe, :public_key),
  secret_key: Rails.application.credentials.backend.dig(:initialize, :stripe, :secret_key)
}

Stripe.api_key = Rails.application.credentials.backend.dig(:initialize, :stripe, :secret_key)
