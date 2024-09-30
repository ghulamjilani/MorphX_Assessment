# frozen_string_literal: true

module LoginHelper
  def omniauth_provider_active?(provider)
    !!Rails.application.credentials.global.dig(:socials, :log_in, provider.to_sym, :active)
  end
end
