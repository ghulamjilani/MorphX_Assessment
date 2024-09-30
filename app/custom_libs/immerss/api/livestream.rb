# frozen_string_literal: true

module Immerss
  module Api
    class Livestream
      def self.client
        new
      end

      def initialize
        @client = Excon.new(ENV['API_URL'],
                            headers: {
                              'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(
                                ENV['PORTAL_API_LOGIN'], ENV['PORTAL_API_PASSWORD']
                              ),
                              'Content-Type' => 'application/json',
                              'Accept' => 'application/json'
                            },
                            debug_request: !Rails.env.production?,
                            debug_response: !Rails.env.production?,
                            ssl_verify_peer: false)
      end

      def participant_auth(room_id, user_id)
        @method = :post
        @path = "portal/livestreams/#{room_id}/auth/#{user_id}"
        @expected_status = [200, 404]
        @caller = :participant_auth
        sender
      end

      def start_ffmpegservice_stream(room_id)
        @method = :post
        @path = "scheduling_service/sessions/#{room_id}/start_ffmpegservice_stream"
        @expected_status = [200]
        @caller = :start_ffmpegservice_stream
        sender
      end

      private

      def sender
        query = @query.is_a?(Hash) ? @query : {}
        query[:time_travel] = Time.now unless Rails.env.production?

        exists_path = @client.data[:path]
        path = if exists_path.present? && exists_path != '/'
                 exists_path + @path
               else
                 @path
               end

        @client.request(expects: @expected_status, method: @method, path: path, query: query)
      rescue StandardError => e
        Airbrake.notify(RuntimeError.new("Server #{ENV['API_URL']} return exception for method Livestream.#{@caller}"),
                        parameters: {
                          message: e.message,
                          expects: @expected_status,
                          method: @method,
                          path: @path,
                          query: @query
                        })
        false
      end
    end
  end
end
