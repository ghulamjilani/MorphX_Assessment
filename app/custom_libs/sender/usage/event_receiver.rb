# frozen_string_literal: true

module Sender
  module Usage
    class EventReceiver
      class << self
        def client(user = nil)
          new(user)
        end
      end

      def initialize(user = nil)
        @user = user
        @base_url = ::Usage.config.dig(:event_receiver, :base_url)
      end

      def user_messages(user_messages, params = {})
        @method = :post
        @path = ::Usage.config.dig(:event_receiver, :paths, :user_messages)
        @expected_status = params[:expected_status] || [200]
        @body = { messages: user_messages }.to_json
        sender[:messages]
      end

      def system_messages(messages, params = {})
        @method = :post
        @path = ::Usage.config.dig(:event_receiver, :paths, :system_messages)
        @expected_status = params[:expected_status] || [200]
        @body = { messages: messages }.to_json
        sender[:messages]
      end

      private

      def sender
        response = client.request(
          idempotent: true, retry_limit: 1, retry_interval: 1, expects: @expected_status,
          method: @method, path: @path, body: @body, query: @query
        )
        @body = nil
        if response&.body.blank? || response&.status.eql?(404)
          {}
        else
          JSON.parse(response.body).with_indifferent_access[:response]
        end
      rescue StandardError => e
        Rails.logger.debug e unless Rails.env.production?
        Airbrake.notify(e, parameters: {
                          path: @path,
                          method: @method,
                          query: @query,
                          body: @body,
                          response: response,
                          response_body: response&.body
                        })
        {}
      end

      def client
        Excon.new(@base_url,
                  headers: {
                    'Authorization' => ::Auth::Jwt::Encoder.new(type: 'usage', model: @user).jwt,
                    'Content-Type' => 'application/json',
                    'Accept' => 'application/json'
                  },
                  debug_request: !Rails.env.production?,
                  debug_response: !Rails.env.production?,
                  ssl_verify_peer: false)
      end
    end
  end
end
