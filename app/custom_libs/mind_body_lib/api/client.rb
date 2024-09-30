# frozen_string_literal: true

module MindBodyLib
  module Api
    class Client
      def initialize(credentials: {})
        credentials = ActiveSupport::HashWithIndifferentAccess.new(credentials)
        %w[username password site_id token].each do |k|
          instance_variable_set("@#{k}", credentials[k])
        end
        @username ||= 'Siteowner'
        @password ||= 'apitest1234'
        @client = Excon.new('https://api.mindbodyonline.com',
                            headers: {
                              'Api-Key' => ENV['MIND_BODY_API_KEY'],
                              'SiteId' => @site_id,
                              'Content-Type' => 'application/json',
                              'Accept' => 'application/json'
                            },
                            debug_request: !Rails.env.production?,
                            debug_response: !Rails.env.production?)
        @expected_status = [200, 201]
      end

      def token
        @expected_status = [200, 201, 422]
        @method = :post
        @body = {
          'Username': @username,
          'Password': @password
        }.to_json
        @path = '/public/v6/usertoken/issue'
        sender
      end

      def activation_link
        @expected_status = [200, 201, 422, 403, 500]
        @method = :get
        @path = '/public/v6/site/activationcode'
        sender['ActivationLink']
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

      def filtered_params
        @allowed ||= {}
        @allowed = ActiveSupport::HashWithIndifferentAccess.new(@allowed)
        @required ||= []
        @params ||= {}
        params = ActiveSupport::HashWithIndifferentAccess.new(@params).filter do |k, v|
          @allowed.key?(k) && (v.is_a? @allowed[k])
        end
        missing = @required.reject do |r|
          params.key?(r.to_sym)
        end
        raise "Required params missing: #{missing.join(' ,')}" if missing.present?

        {
          Limit: 100,
          Offset: 0
        }.merge params.to_h.symbolize_keys
      end
    end
  end
end
