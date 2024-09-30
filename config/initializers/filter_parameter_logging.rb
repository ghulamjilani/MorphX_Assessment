# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += %i[current_password
                                                 password
                                                 password_confirmation
                                                 secret
                                                 secret_key]

# Filter base64 images
Rails.application.config.filter_parameters << lambda do |_k, v|
  if v.present? && v.class == String && v.starts_with?('data:image/')
    v.replace('[FILTERED]')
  end
end
