# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
if ENV['SIMPLECOV']
  require 'simplecov'
  SimpleCov.start
end

def require_all(*patterns)
  options = patterns.pop
  patterns.each { |pattern| Dir[pattern].sort.each { |path| require path.gsub(%r{^#{options[:relative_to]}/}, '') } }
end

require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'

require 'rspec/its'
require 'webmock/rspec'
require 'carrierwave/test/matchers'
require 'sidekiq/testing'
require 'rspec/rails/shared_contexts/action_cable'
# require 'action_cable/testing/rspec'
# require 'action_cable/testing/rspec/features'
Sidekiq::Testing.fake!
require_all 'spec/support/**/*.rb', relative_to: 'spec'
require_all 'spec/acceptance/steps/**/*_steps.rb', relative_to: 'spec'
require_all 'spec/steps/**/*_steps.rb', relative_to: 'spec'

# ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

WebMock.disable_net_connect!(allow_localhost: true)

VCR.configure do |c|
  c.cassette_library_dir = File.join(File.dirname(__FILE__), '..', 'spec', 'fixtures', 'cassettes')
  c.default_cassette_options = {
    record: :new_episodes,
    decode_compressed_response: true,
    serialize_with: :json,
    preserve_exact_body_bytes: true
  }
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.ignore_hosts 'graph.facebook.com'
  c.ignore_hosts 'zoom.us'
  c.ignore_hosts '127.0.0.1'
  c.ignore_hosts 'localhost'
  c.ignore_hosts 'webrtcservice.com'
  c.ignore_hosts 'video.webrtcservice.com'
  c.ignore_hosts 'chat.webrtcservice.com'
  c.ignore_hosts 'video.webrtcservice.com'
  c.ignore_hosts 'www.webrtcservice.com'
  c.ignore_hosts 'cloud.ffmpegservice.com'
  c.ignore_hosts 'sandbox.cloud.ffmpegservice.com'
  c.ignore_hosts 'api.video.ffmpegservice.com'
  c.ignore_hosts 'api-sandbox.cloud.ffmpegservice.com'
  c.ignore_hosts ENV['HWCDN']
  c.ignore_request do |request|
    headers = request.headers['User-Agent']
    ignore_by_user_agent = headers.present? && (headers.first == 'Ruby' || headers.first.include?('Braintree'))

    ignore_by_user_agent || ['solr'].any? { |chunk| request.uri.include?(chunk) }
  end
end
RSpec.configure do |c|
  c.use_transactional_fixtures = true
  c.raise_errors_for_deprecations!
  c.infer_spec_type_from_file_location!
  c.order = :random
  c.seed = srand % 0xFFFF

  c.include Devise::Test::ControllerHelpers, type: :controller
  c.include Devise::Test::ControllerHelpers, type: :view
  c.include FactoryBot::Syntax::Methods
  c.include SystemParametersHelper
  c.include WebMock::API
  c.include SearchModelsHelper
  c.include ActionCable::TestHelper

  c.mock_with :rspec

  c.before(:suite) do
    # create default channel type
    FactoryBot.create(:not_selected_channel_type)
    ::AccessManagement::Credential::Codes.active.each do |credential_code|
      FactoryBot.create(:access_management_credential, code: credential_code)
    end
    UniteMigrations.recreate_plutus_accounts
  end

  c.before do
    ENV['SKIP_IMAGES_COUNT_CHECK'] = '1'
    ENV['SKIP_OVERLAP_CHECK'] = '1'

    OmniAuth.config.test_mode = true

    @stripe_test_helper = StripeMock.create_test_helper
    StripeMock.start

    Mongoid::Clients.default.collections.reject { |o| o.name == 'system.indexes' }.each do |co|
      co.with(write: { w: 0 }).delete_many
    end

    begin
      Rails.cache.clear
    rescue StandardError
      nil
    end
    Sidekiq::Worker.clear_all
    ActionMailer::Base.deliveries.clear
    stub_system_parameters

    Time.zone = 'Almaty'
    Chronic.time_class = Time.zone
  end

  c.after do
    StripeMock.stop
    VCR.eject_cassette
    Timecop.return
    FileUtils.rm_rf(Rails.root.join('public/uploads/test'))
    FileUtils.rm_rf(Rails.root.join('public/uploads/tmp'))
    FileUtils.rm_rf(ActiveStorage::Blob.service.root)
  end

  c.after(:suite) do
    FileUtils.rm_rf(Dir[Rails.root.join('/spec/support/uploads')]) if Rails.env.test?
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec::Matchers.define_negated_matcher :not_change, :change
RSpec::Matchers.define_negated_matcher :not_raise_error, :raise_error
