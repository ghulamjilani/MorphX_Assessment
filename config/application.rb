# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
# require "active_job/railtie"
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'mail'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'
require_relative 'over_creds'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Immerss
  class Application < Rails::Application
    attr_accessor :over_creds

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    unless ENV['SKIP_MIGRATE_CONFIG']
      config.paths['db/migrate'] = UniteMigrations::Engine.paths['db/migrate'].existent
    end

    config.app_generators.scaffold_controller = :scaffold_controller
    config.generators.stylesheets = false
    config.generators.javascripts = false
    config.active_record.cache_versioning = false
    config.generators do |g|
      g.orm :active_record
      g.template_engine :jbuilder
      g.test_framework  :rspec
    end

    if Rails.env.development?
      config.middleware.insert_before 0, Rack::Cors do
        allow do
          origins '*'
          resource(
            '*',
            headers: :any,
            methods: %i[get patch put delete post options]
          )
        end
      end
    end

    # config.autoload_paths += %W(#{config.root}/lib #{config.root}/app/mailers/abilities)
    # config.eager_load_paths += %W(#{config.root}/lib #{config.root}/app/mailers/abilities)

    # FIXME: move libs to app folders
    # https://edgeguides.rubyonrails.org/autoloading_and_reloading_constants.html#autoload-paths-and-eager-load-paths
    # config.autoload_paths += [
    #     # Rails.root.join('app/models/concerns'),
    #     # Rails.root.join('app/interactors/concerns'),
    #     # Rails.root.join('app/jobs'),
    #     Rails.root.join('lib'),
    #     # Rails.root.join('app/presenters')
    # ]
    # config.eager_load_paths  += [
    #     # Rails.root.join('app/models/concerns'),
    #     # Rails.root.join('app/interactors/concerns'),
    #     # Rails.root.join('app/jobs'),
    #     Rails.root.join('lib'),
    #     # Rails.root.join('app/presenters')
    # ]

    # #"customize the layout of your error handling using controllers and views"
    config.exceptions_app = routes
    config.active_record.belongs_to_required_by_default = false
    config.active_record.schema_format = :sql
    config.active_record.yaml_column_permitted_classes = [
      ActiveSupport::HashWithIndifferentAccess,
      ActiveSupport::TimeWithZone,
      ActiveSupport::TimeZone,
      BigDecimal,
      Date,
      PayPal::SDK::Core::API::DataTypes::SimpleTypes::String,
      Symbol,
      Time
    ]
    console do
      ARGV.push '-r', root.join('lib/console.rb')
    end

    config.action_mailer.preview_path = "#{Rails.root}/spec/mailers/previews"

    config.action_cable.mount_path = '/cable'

    config.action_view.sanitized_allowed_tags = %w[a b i br s u ul ol li p strong em]
    config.action_view.sanitized_allowed_attributes = %w[href title target]

    config.log_tags = [:remote_ip, :uuid, proc { format('PID: %.5d', Process.pid) }]
    config.active_storage.variant_processor = :mini_magick
  end
end
