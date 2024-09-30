# frozen_string_literal: true

module Everflow
  class ApiResource
    API_BASE = 'https://api.eflow.team'

    def self.retrieve(id)
      url = "#{API_BASE}#{resource_path}/#{id}"
      response = Excon.get(url, headers: headers)
      parse_response(response)
    end

    def self.resource_path
      if self == ApiResource
        raise NotImplementedError,
              'Everflow::APIResource is an abstract class. You should perform actions on its subclasses (Transaction, Offer, etc.)'
      end

      "/v1/#{self::OBJECT_NAME.downcase.tr('.', '/')}s"
    end

    def self.headers
      unless Rails.application.credentials.backend.dig(:initialize, :everflow, :api_key)
        raise 'No API Key provided. Please add API Key in Config.'
      end

      {
        'Content-Type': 'application/json',
        'x-eflow-api-key': Rails.application.credentials.backend[:initialize][:everflow][:api_key]
      }
    end

    def self.parse_response(response)
      case response.status
      when 200
        JSON.parse(response.body, symbolize_names: true)
      when 404
        raise JSON.parse(response.body, symbolize_names: true)[:error]
      end
    end
  end
end
