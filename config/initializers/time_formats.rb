# frozen_string_literal: true

MORPHX_TIME_FORMAT = :morphx_time_format
MORPHX_DETAILED_TIME_FORMAT = :morphx_detailed_time_format
MORPHX_SHORT_TIME_FORMAT = :morphx_short_time_format

Time::DATE_FORMATS[:rfc3339] = "%Y-%m-%d\T%H:%M:%S.%3N%:z"
Time::DATE_FORMATS[MORPHX_TIME_FORMAT] = ->(time) { time.strftime('%H:%M %d %b %Y %Z') }

Time::DATE_FORMATS[MORPHX_DETAILED_TIME_FORMAT] = lambda do |time|
  offset_format = time.formatted_offset
  time.strftime("%d %b %Y %H:%M:%S %Z(#{offset_format})")
end

Time::DATE_FORMATS[MORPHX_SHORT_TIME_FORMAT] = lambda do |time|
  time.strftime('%H:%M %d %b %Z')
end
