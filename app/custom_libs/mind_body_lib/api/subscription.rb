# frozen_string_literal: true

module MindBodyLib
  module Api
    class Subscription < MindBodyLib::Api::Client
      def initialize
        @client = Excon.new('https://mb-api.mindbodyonline.com',
                            headers: {
                              'Api-Key' => ENV['MIND_BODY_API_KEY'],
                              'Content-Type' => 'application/json',
                              'Accept' => 'application/json'
                            },
                            debug_request: !Rails.env.production?,
                            debug_response: !Rails.env.production?)
        @expected_status = [200, 201]
      end

      def all
        @path = '/push/api/v1/subscriptions'
        @method = :get
        sender
      end

      def active(s_id)
        @path = "/push/api/v1/subscriptions/#{s_id}"
        @body = {
          status: 'Active'
        }.to_json
        @method = :patch
        sender
      end

      def create
        domain = if Rails.env.production?
                   'https://unite.live'
                 elsif Rails.env.qa?
                   'https://qa-portal.unite.live'
                 else
                   "#{ENV['PROTOCOL']}#{ENV['HOST']}"
                 end

        @path = '/push/api/v1/subscriptions'
        @body = {
          'eventIds': MindBodyLib::Map.events,
          'eventSchemaVersion': 1,
          'referenceId': Rails.env.to_s,
          'webhookUrl': "#{domain}/webhook/v1/mind_body_online"
        }.to_json
        @method = :post
        sender
      end
    end
  end
end
