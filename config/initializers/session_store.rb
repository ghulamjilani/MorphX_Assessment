# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

key = if Rails.env.production?
        "_#{Rails.application.credentials.global[:project_name].to_s.downcase}_n_session"
      else
        "_#{Rails.application.credentials.global[:project_name].to_s.downcase}_#{Rails.env}_n_session"
      end

Rails.application.config.session_store :cookie_store, key: key
