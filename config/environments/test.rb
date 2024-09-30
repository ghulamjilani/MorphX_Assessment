# frozen_string_literal: true

# because otherwise I18n.t can't find tokens in initializer
# and googling stackoveflow only gives even worse solutions

Rails.application.configure do
  config.before_configuration do
    Rails.application.instance_variable_set(:@credentials, OverCreds.new('test').config)
  end

  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  config.assets.js_compressor = Uglifier.new(harmony: true)
  config.assets.css_compressor = :scss

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  # config.assets.compile = false
  config.assets.unknown_asset_fallback = false

  # Generate digests for assets URLs.
  config.assets.digest = true
  config.assets.prefix = '/test_assets'

  # Version of your assets, change this if you want to expire all your assets.
  config.assets.version = '1.0.1'
  # Configure static asset server for tests with Cache-Control for performance.
  config.serve_static_files = true
  config.static_cache_control = 'public, max-age=3600'

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = { host: 'localhost' }
  config.action_mailer.asset_host = ENV['ASSET_HOST']
  config.action_mailer.default_options = { from: (Rails.application.credentials.global[:mailer_from] or raise 'mailer.from must be present in config') }

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :log

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  #
  # config.active_job.queue_adapter     = :inline
  # config.active_job.queue_adapter     = :inline
  config.active_job.queue_adapter = :test

  config.after_initialize do
    Mail.register_interceptor EmailsDomainInterceptor
  end

  config.active_record.verbose_query_logs = true
  config.log_level = ENV['VERBOSE'] ? :debug : :warn
  config.hosts << /[a-z0-9]+\.morphx\.io/
  config.hosts << 'unite.live'
  config.hosts << 'localhost'
  config.hosts << ENV['HOST'] if ENV['HOST'].present?
end
