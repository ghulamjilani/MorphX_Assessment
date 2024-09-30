# frozen_string_literal: true

module MindBodyLib
  module Api
    class ClassRoom < MindBodyLib::Api::Client
      # https://developers.mindbodyonline.com/PublicDocumentation/V6#get-classes
      # Accepts hash with the following keys:
      # 'ClassDescriptionIds', optional, list of numbers
      # 'ClassIds', optional, list of numbers
      # 'StaffIds', optional, list of numbers
      # 'StartDateTime', optional, string
      # 'EndDateTime', optional, string
      # 'ClientId', optional, string
      # 'ProgramIds', optional, list of numbers
      # 'SessionTypeIds', optional, list of numbers
      # 'LocationIds', optional, list of numbers
      # 'SemesterIds', optional, list of numbers
      # 'HideCanceledClasses', optional, boolean
      # 'SchedulingWindow', optional, boolean
      # 'LastModifiedDate', optional, string
      # 'Limit', optional, number
      # 'Offset', optional, number
      def class_rooms(params = {})
        @params = params
        @allowed = {
          ClassDescriptionIds: Array,
          ClassIds: Array,
          StaffIds: Array,
          StartDateTime: String,
          EndDateTime: String,
          ClientId: String,
          ProgramIds: Array,
          SessionTypeIds: Array,
          LocationIds: Array,
          SemesterIds: Array,
          HideCanceledClasses: Boolean,
          SchedulingWindow: Boolean,
          LastModifiedDate: String,
          Limit: Integer,
          Offset: Integer
        }
        @query = filtered_params if filtered_params.present?
        @path = '/public/v6/class/classes'
        @method = :get
        sender
      end
    end
  end
end
