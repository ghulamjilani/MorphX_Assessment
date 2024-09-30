# frozen_string_literal: true

Rails.configuration.middleware.use Browser::Middleware do
  next unless request.get?
  next if browser.bot?
  next if browser.bot.search_engine?
  next if request.user_agent == 'ELB-HealthChecker/1.0'
  next if request.user_agent == 'PayPal IPN ( https://www.paypal.com/ipn )'
  next if request.user_agent.to_s.downcase.include?('immerssstagingqa')
  next if request.user_agent.to_s.downcase.include?('immerss')
  next if request.user_agent.to_s.downcase.include?('unite')
  next if request.user_agent.to_s.downcase.include?('tumblr')
  next if request.user_agent.to_s.downcase.include?('powerpoint')
  next if request.user_agent.to_s.downcase.include?('cocoarestclient')
  next if request.fullpath.to_s.downcase.include?('powerpoint')
  next if request.fullpath.to_s.downcase.include?(ContentPages::IE_BROWSER.parameterize(separator: '-'))
  next if request.fullpath.to_s.start_with?('/api/v1/')

  redirect_to ContentPages::IE_BROWSER.parameterize(separator: '-') if browser.ie?

  modern_browser = [
    browser.chrome?('>= 65'),
    browser.safari?('>= 10'),
    browser.firefox?('>= 52'),
    browser.ie?('>= 11') && !browser.compatibility_view?,
    browser.edge?('>= 15'),
    browser.opera?('>= 50'),
    browser.device.samsung?,
    browser.uc_browser?,
    browser.facebook? || browser.safari_webapp_mode? || browser.webkit_full_version.to_i >= 602
  ].any?
  redirect_to page_path(ContentPages::OLD_BROWSER.parameterize(separator: '-')) unless modern_browser

# Fixes NoMethodError: undefined method `downcase' for nil:NilClass
# this is caused by absent USER_AGENT parameter
# browser-2.0.1/lib/browser/bot.rb:61→ downcased_ua
# browser-2.0.1/lib/browser/bot.rb:53→ block in bot_exception?
# browser-2.0.1/lib/browser/bot.rb:53→ any?
# browser-2.0.1/lib/browser/bot.rb:53→ bot_exception?
# browser-2.0.1/lib/browser/bot.rb:33→ bot?
# browser-2.0.1/lib/browser/base.rb:47→ bot?
# config/initializers/browser.rb:2→ block in <top (required)>
rescue NoMethodError => e
  Rails.logger.warn e.message
  Rails.logger.warn e.backtrace
  next
end
