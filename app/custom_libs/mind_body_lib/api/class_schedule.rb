# frozen_string_literal: true

module MindBodyLib
  module Api
    class ClassSchedule < MindBodyLib::Api::Client
      # https://developers.mindbodyonline.com/PublicDocumentation/V6#get-class-schedules
      # Accepts hash with the following keys:
      # 'ClassScheduleIds', optional, list of numbers
      # 'LocationIds', optional, list of numbers
      # 'ProgramIds', optional, list of numbers
      # 'SessionTypeIds', optional, list of numbers
      # 'StaffIds', optional, list of numbers
      # 'StartDate', optional, string
      # 'EndDate', optional, string
      # 'Limit', optional, number
      # 'Offset', optional, number
      def class_schedules(params = {})
        @params = params
        @allowed = {
          ClassScheduleIds: Array,
          LocationIds: Array,
          ProgramIds: Array,
          SessionTypeIds: Array,
          StaffIds: Array,
          StartDate: String,
          EndDate: String,
          Limit: Integer,
          Offset: Integer
        }
        @query = filtered_params if filtered_params.present?
        @path = '/public/v6/class/classschedules'
        @method = :get
        sender
      end
    end
  end
end
