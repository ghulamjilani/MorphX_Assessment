# frozen_string_literal: true

# https://guides.rubyonrails.org/i18n.html

# Permitted locales available for the application
I18n.available_locales = [:en]

# Set default locale to something other than :en
I18n.default_locale = :en

Rails.application.config.to_prepare do
  project_name = Rails.application.credentials.global[:project_name].to_s.downcase
  Rails.application.config.i18n.load_path += Dir[Rails.root.join('config', 'locales_override', project_name, '**', '*.{yml}')]
end
