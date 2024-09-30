# frozen_string_literal: true

module MindBodyLib
  module Api
    class Site < MindBodyLib::Api::Client
      # https://developers.mindbodyonline.com/PublicDocumentation/V6#get-sites
      def sites(params = {})
        @params = params
        @allowed = {
          SiteIds: Array,
          Limit: Integer,
          Offset: Integer
        }
        @query = filtered_params if filtered_params.present?
        @path = '/public/v6/site/sites'
        @method = :get
        sender
      end
    end
  end
end
