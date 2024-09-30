# frozen_string_literal: true

require 'authy'

Authy.api_uri = 'https://api.authy.com'
Authy.api_key = Rails.application.credentials.backend.dig(:initialize, :webrtcservice, :authy, :api_key)
