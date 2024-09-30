# frozen_string_literal: true

module ActiveAdmin
  module TimeHelper
    def utc_and_admin_time_formatted(time, time_format = MORPHX_DETAILED_TIME_FORMAT)
      return nil if time.blank?

      admin_time_zones_array.map do |tz|
        time.in_time_zone(tz).to_fs(time_format).gsub(' ', '&nbsp;')
      end.join('<br>').html_safe
    end

    private

    def admin_time_zones_array
      [
        ActiveSupport::TimeZone['UTC'],
        ActiveSupport::TimeZone[current_admin.manually_set_timezone.to_s]
      ].compact.map(&:name).uniq
    end
  end
end
