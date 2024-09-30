# frozen_string_literal: true

# MESSAGE = {
#
#     "topic":"weat3her",
#     "notification": {
#         "title":"Check out this sale!",
#         "body":"All items half off through Friday"
#     },
#     "android":{
#         "notification": {
#             "click_action":"OPEN_ACTIVITY_3"
#         }
#     },
#     "apns": {
#         "payload": {
#             "aps": {
#                 "category": "SALE_CATEGORY"
#             }
#         }
#     }
# }

module Sender
  class FirebaseLib
    def self.config=(full_path)
      @config = JSON.parse(full_path)
    end

    class << self
      attr_reader :config
    end

    attr_accessor :sync

    def self.send(message:, sandbox: nil, sync: false)
      sandbox = sandbox.nil? ? Rails.env.development? : sandbox
      payload = {
        validate_only: sandbox,
        message: message
      }.to_json
      obj = new
      obj.sync = sync
      obj.send_notice(payload)
    end

    def initialize
      return true if Rails.env.test?

      @expected_status = [200, 400]
      @sync = false

      ENV[::Google::Auth::CredentialsLoader::PRIVATE_KEY_VAR]   = self.class.config['private_key']
      ENV[::Google::Auth::CredentialsLoader::CLIENT_EMAIL_VAR]  = self.class.config['client_email']
      ENV[::Google::Auth::CredentialsLoader::PROJECT_ID_VAR]    = self.class.config['project_id']

      scope = %w[
        https://www.googleapis.com/auth/firebase
        https://www.googleapis.com/auth/firebase.messaging
        https://www.googleapis.com/auth/cloud-platform
      ]
      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(scope: scope)

      @client = Excon.new('https://fcm.googleapis.com',
                          headers: {
                            'Authorization' => "Bearer #{authorizer.fetch_access_token!['access_token']}",
                            'Content-Type' => 'application/json',
                            'Accept' => 'application/json'
                          },
                          debug_request: !Rails.env.production?,
                          debug_response: !Rails.env.production?)
    end

    def send_notice(payload_json)
      return {} if Rails.env.test?

      @method = :post
      @path = "/v1/projects/#{self.class.config['project_id']}/messages:send"

      @body = payload_json

      async_sender
    end

    private

    def sender
      response = @client.request(expects: @expected_status, method: @method, path: @path, body: @body, query: @query)
      begin
        if response.body.blank?
          {}
        else
          JSON.parse(response.body).with_indifferent_access
        end
      rescue StandardError => e
        Airbrake.notify(e.message,
                        parameters: {
                          body: response.body
                        })
        {}
      end
    end

    def async_sender
      @sync ? sender : Thread.new { puts sender }
    end
  end
end
