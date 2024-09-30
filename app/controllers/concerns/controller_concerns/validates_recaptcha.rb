# frozen_string_literal: true

module ControllerConcerns
  module ValidatesRecaptcha
    extend ActiveSupport::Concern

    included do
      helper_method :recaptcha_verified?
      helper_method :recaptcha_form_field_enabled?
    end

    def recaptcha_verified?(form_name = nil)
      return true unless recaptcha_form_field_enabled?(form_name)

      verify_recaptcha
    end

    def recaptcha_form_field_enabled?(form_name = nil)
      return false if Rails.application.credentials.global.dig(:recaptcha, :enabled).blank? ||
                      Rails.application.credentials.global.dig(:recaptcha, :site_key).blank? ||
                      Rails.application.credentials.backend.dig(:initialize, :recaptcha, :secret_key).blank?
      return true if form_name.blank?

      Rails.application.credentials.global.dig(:recaptcha, :forms_disabled, form_name.to_sym).blank?
    end
  end
end
