# frozen_string_literal: true

# because otherwise I18n.t can't find tokens in initializer
# and googling stackoveflow only gives even worse solutions

Rails.application.configure do
  config.before_configuration do
    Rails.application.instance_variable_set(:@credentials, OverCreds.new('development', true).config)
  end

  config.after_initialize do
    Bullet.enable = true
    Bullet.rails_logger = true
    Mail.register_interceptor ::EmailsEnvSubjectInterceptor
  end

  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Use a different cache store in production
  config.cache_store = :redis_cache_store, { url:"#{ENV['SESSION_REDIS_URL']}/cache", expires_in: 1.hour }

  # Show full error reports.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = true

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { host: ENV['HOST'], protocol: ENV['PROTOCOL'] }
  config.action_mailer.asset_host = ENV['ASSET_HOST']
  config.action_mailer.default_options = { from: (Rails.application.credentials.global[:mailer_from] or raise 'mailer.from must be present in config') }

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :stderr

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true
  logger = ActiveSupport::Logger.new(Rails.root.join('log', "development.#{`hostname`.to_s.strip}.log"))
  # Use default logging formatter so that PID and timestamp are not suppressed.
  logger.formatter = ::Logger::Formatter.new
  config.logger = ActiveSupport::TaggedLogging.new(logger)
  config.log_level = :debug

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = false

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true
  config.assets.compile = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.active_job.queue_adapter = :sidekiq
  config.action_dispatch.default_headers = {
    'Referrer-Policy' => 'origin-when-cross-origin' # because mixin content on other sites a block our iframe's with widgets
  }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = { address: 'localhost', port: 1025 }

  allowed_hosts = Rails.application.credentials.backend.dig(:initialize, :allowed_hosts).to_a
  allowed_hosts << ENV['HOST'] if ENV['HOST'].present?
  allowed_hosts = allowed_hosts.flatten.compact.uniq
  config.hosts += allowed_hosts

  if Rails.application.credentials.backend[:action_cable][:url].present?
    config.action_cable.url = Rails.application.credentials.backend[:action_cable][:url]
  end
  config.action_cable.allowed_request_origins = allowed_hosts + Rails.application.credentials.backend.dig(:action_cable, :allowed_request_origins).to_a

  config.middleware.use Rack::Attack
end
