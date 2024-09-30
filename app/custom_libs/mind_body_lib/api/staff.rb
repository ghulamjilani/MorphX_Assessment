# frozen_string_literal: true

module MindBodyLib
  module Api
    class Staff < MindBodyLib::Api::Client
      # https://developers.mindbodyonline.com/PublicDocumentation/V6#get-staff
      # Accepts hash with the following keys:
      # 'StaffIds', optional, list of numbers
      # 'Filters', optional, list of numbers
      # 'SessionTypeId', optional, list of numbers
      # 'StartDateTime', optional, list of numbers
      # 'LocationId', optional, list of numbers
      # 'Limit', optional, number
      # 'Offset', optional, number
      def staffs(params = {})
        @params = params
        @allowed = {
          StaffIds: Array,
          Filters: Array,
          SessionTypeId: Integer,
          StartDateTime: String,
          LocationId: Integer,
          Limit: Integer,
          Offset: Integer
        }
        @query = filtered_params if filtered_params.present?
        @path = '/public/v6/staff/staff'
        @method = :get
        sender
      end
    end
  end
end
