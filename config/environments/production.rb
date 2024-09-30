# frozen_string_literal: true

# because otherwise I18n.t can't find tokens in initializer
# and googling stackoveflow only gives even worse solutions

Rails.application.configure do
  config.before_configuration do
    Rails.application.instance_variable_set(:@credentials, OverCreds.new('production').config)
  end

  config.action_mailer.smtp_settings = {
    address: ENV['SMTP_SERVER'],
    port: ENV['SMTP_PORT'],
    authentication: :plain,
    user_name: ENV['SMTP_USERNAME'],
    password: ENV['SMTP_PASSWORD'],
    domain: ENV['SMTP_DOMAIN']
  }

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  config.font_assets.origin = Rails.application.credentials.backend[:font_assets_origin]

  allowed_hosts = Rails.application.credentials.backend.dig(:initialize, :allowed_hosts).to_a
  allowed_hosts << ENV['HOST'] if ENV['HOST'].present?
  allowed_hosts = allowed_hosts.flatten.compact.uniq
  config.hosts += allowed_hosts

  if Rails.application.credentials.backend[:action_cable][:url].present?
    config.action_cable.url = Rails.application.credentials.backend[:action_cable][:url]
  end
  config.action_cable.allowed_request_origins = allowed_hosts + Rails.application.credentials.backend.dig(:action_cable, :allowed_request_origins).to_a

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both thread web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Generate digests for assets URLs.
  config.assets.digest = true

  # Version of your assets, change this if you want to expire all your assets.
  config.assets.version = '1.0.1'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # See everything in the log (default is :info)
  config.log_level = :info

  # Use a different log filename for load balancing
  # https://github.com/rails/sprockets-rails/issues/376
  # NoMethodError: undefined method 'silence' for #<Logger:...>
  logger           = ActiveSupport::Logger.new(Rails.root.join('log', "production.#{`hostname`.to_s.strip}.log"))
  # Use default logging formatter so that PID and timestamp are not suppressed.
  logger.formatter = ::Logger::Formatter.new
  config.logger = ActiveSupport::TaggedLogging.new(logger)
  # Use a different cache store in production
  config.cache_store = :redis_cache_store, { url: "#{ENV['SESSION_REDIS_URL']}/cache",  expires_in: 1.day }

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_files = false

  # Enable serving of images, stylesheets, and javascripts from an asset server
  config.action_controller.asset_host = ENV['ASSET_HOST']

  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { host: ENV['HOST'], protocol: ENV['PROTOCOL'] }
  config.action_mailer.asset_host = ENV['PROTOCOL'].to_s + ENV['HOST'].to_s
  config.action_mailer.default_options = { from: (Rails.application.credentials.global[:mailer_from] or raise 'mailer.from must be present in config') }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Compress both stylesheets and JavaScripts
  config.assets.js_compressor = :uglify_with_source_maps
  config.assets.css_compressor = :scss

  config.middleware.use Rack::Attack
  config.assets.prefix = '/assets'

  config.active_job.queue_adapter = :sidekiq
  config.active_storage.service = :amazon
  config.action_dispatch.default_headers = {
    # 'Content-Security-Policy' =>
    #     "default-src 'self' https://accounts.google.com; " \
    # "img-src 'self' https://accounts.google.com https://travis-ci.org https://api.travis-ci.org; " \
    # "media-src 'none'; " \
    # "object-src 'none'; " \
    # "script-src 'self' https://accounts.google.com; " \
    # "style-src 'self' https://accounts.google.com https://travis-ci.org; ",
    'Referrer-Policy' => 'origin-when-cross-origin' # because mixin content on other sites a block our iframe's with widgets
    # 'X-Content-Type-Options' => 'nosniff',
    # 'X-Frame-Options' => 'SAMEORIGIN',
    # 'X-XSS-Protection' => '1; mode=block'
  }
  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
  config.hosts << ENV['HOST'] if ENV['HOST'].present?
end
