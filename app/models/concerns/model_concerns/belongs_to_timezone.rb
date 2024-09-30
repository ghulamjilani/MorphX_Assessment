# frozen_string_literal: true

module ModelConcerns::BelongsToTimezone
  extend ActiveSupport::Concern

  class_methods do
    def available_timezones
      ActiveSupport::TimeZone.all.select { |tz| tz.to_s.include?(':30') || tz.to_s.include?(':00') }
    end

    def timezone_enum
      available_timezones.map { |tz| [tz.to_s, tz.tzinfo.name] }
    end
  end
end
