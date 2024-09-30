# frozen_string_literal: true

module ControllerConcerns::GoService
  extend ActiveSupport::Concern

  included do
    before_action :check_if_has_needed_cookie
  end

  def check_if_has_needed_cookie
    go_creds = Rails.application.credentials.backend[:go]
    return unless go_creds
    return unless go_creds[:enable]
    return if Rails.env.test?
    return if request.user_agent.to_s.include?('Google')
    return if request.user_agent.to_s.include?('Facebot')
    return if request.user_agent.to_s.include?('facebookexternalhit')
    return if request.user_agent.to_s.include?('LinkedInBot')
    return if request.user_agent.to_s.include?('Pinterest')
    return if request.user_agent.to_s.include?('Reddit')
    return if request.user_agent.to_s.include?('Tumblr')
    return if request.user_agent.to_s.include?('Twitterbot')
    return if request.user_agent.to_s.include?('bitlybot')
    return if request.user_agent.to_s.include?('Slackbot-LinkExpanding')
    return if request.subdomains.size >= 2
    return if request.path.to_s.include?('api_portal')
    return if request.path.to_s.include?('callback')
    return if request.path.to_s.include?('paypal')
    return if request.path.to_s.include?(Rails.application.credentials.backend[:go][:cookie_key])
    return if request.path.to_s.include?('services')

    # Victor Gushek set custom user agent for qa
    return if request.user_agent.to_s.downcase.include?('immerssstagingqa') || request.user_agent.to_s.downcase.include?('immersstagingqa') || request.user_agent.to_s.downcase.include?('immerss')
    return if request.user_agent.to_s.downcase.include?('unite')

    if cookies[go_creds[:cookie_key]].blank?
      file = "#{Rails.root}/public/services/#{Rails.application.credentials.global[:project_name].to_s.downcase}/index.html"
      if File.exist?(file)
        render file: file, layout: false
      else
        body = %(
          <h2>Access Denied</h2>
          <p>You are not eligible to view this page. If you think this is an error, contact your IT administrator for help.</p>
        )
        render plain: body, layout: false
      end
    end
  end
end
