# frozen_string_literal: true

module MindBodyLib
  module Api
    class Location < MindBodyLib::Api::Client
      # https://developers.mindbodyonline.com/PublicDocumentation/V6#get-locations
      def locations(params = {})
        @params = params
        @allowed = {
          Limit: Integer,
          Offset: Integer
        }
        @query = filtered_params if filtered_params.present?
        @path = '/public/v6/site/locations'
        @method = :get
        sender
      end
    end
  end
end
