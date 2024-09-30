# frozen_string_literal: true

if (ar_config = Rails.application.credentials.dig(:backend, :initialize, :airbrake))
  Airbrake.configure do |config|
    config.project_id                   = ar_config[:id]
    config.project_key                  = ar_config[:key]
    config.ignore_environments          = %w[development test cucumber]
    env = if %w[development
                test].include?(Rails.env)
            Rails.env
          else
            (ar_config[:env] || Rails.application.credentials.global[:host] || Rails.env)
          end
    config.environment = env
    config.performance_stats = true
  end

  AIRBRAKE_SKIP_ERRORS = %w[
    AbstractController::ActionNotFound
    ActiveRecord::RecordNotFound ActionController::RoutingError
    ActionController::InvalidAuthenticityToken ActionController::UnknownAction
    ActionController::UnknownHttpMethod
    CGI::Session::CookieStore::TamperedWithCookie
    ActionController::UnknownFormat
  ].freeze

  Airbrake.add_filter do |notice|
    # The library supports nested exceptions, so one notice can carry several
    # exceptions.
    if notice[:errors].any? { |error| AIRBRAKE_SKIP_ERRORS.include?(error[:type]) }
      notice.ignore!
    end
  end
end
