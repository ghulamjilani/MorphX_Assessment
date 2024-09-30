# frozen_string_literal: true

class Api::System::ApplicationController < ActionController::Base
  def http_basic_authenticate(usr = nil, pwd = nil)
    return if Rails.env.test?

    authenticate_or_request_with_http_basic do |username, password|
      username == (usr || ENV['PORTAL_API_LOGIN']) && password == (pwd || ENV['PORTAL_API_PASSWORD'])
    end
  end
end
