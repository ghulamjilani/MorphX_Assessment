# frozen_string_literal: true

Recaptcha.configure do |config|
  config.site_key = Rails.application.credentials.global.dig(:recaptcha, :site_key)
  config.secret_key = Rails.application.credentials.backend.dig(:initialize, :recaptcha, :secret_key)
end
