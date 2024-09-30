# frozen_string_literal: true

module MindBodyLib
  module Api
    class ClassDescription < MindBodyLib::Api::Client
      # https://developers.mindbodyonline.com/PublicDocumentation/V6#get-class-descriptions
      # Accepts hash with the following keys:
      # 'ClassDescriptionId', optional, number
      # 'ProgramIds', optional, list of numbers
      # 'StartClassDateTime', optional, string
      # 'EndClassDateTime', optional, string
      # 'StaffId', optional, number
      # 'LocationId', optional, number
      # 'Limit', optional, number
      # 'Offset', optional, number
      def class_descriptions(params = {})
        @params = params
        @allowed = {
          ClassDescriptionId: Integer,
          ProgramIds: Array,
          StartClassDateTime: String,
          EndClassDateTime: String,
          StaffId: Integer,
          LocationId: Integer,
          Limit: Integer,
          Offset: Integer
        }
        @query = filtered_params if filtered_params.present?
        @path = '/public/v6/class/classdescriptions'
        @method = :get
        sender
      end
    end
  end
end
