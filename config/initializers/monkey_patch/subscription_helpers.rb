# frozen_string_literal: true

module StripeMock
  module RequestHandlers
    module Helpers
      def get_ending_time(start_time, plan, intervals = 1)
        return start_time unless plan

        case plan[:interval]
        when 'week'
          start_time + (604_800 * (plan[:interval_count].to_i || 1) * intervals)
        when 'month'
          (Time.at(start_time).to_datetime >> ((plan[:interval_count].to_i || 1) * intervals)).to_time.to_i
        when 'year'
          (Time.at(start_time).to_datetime >> (12 * intervals)).to_time.to_i # max period is 1 year
        else
          start_time
        end
      end
    end
  end
end
