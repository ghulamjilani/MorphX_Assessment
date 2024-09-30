# frozen_string_literal: true

Koala.configure do |config|
  # config.access_token = MY_TOKEN
  # config.app_access_token = MY_APP_ACCESS_TOKEN
  config.app_id = ENV['FACEBOOK_APP_ID']
  config.app_secret = ENV['FACEBOOK_APP_SECRET']
end
