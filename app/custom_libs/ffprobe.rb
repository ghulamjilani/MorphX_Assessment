# frozen_string_literal: true

class Ffprobe
  class << self
    def get_duration(url)
      return '' unless installed?

      `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 '#{url}'`
    end

    def installed?
      return true if Rails.env.test?

      result = `dpkg -l | grep ffmpeg 2>&1`
      Airbrake.notify('ffmpeg is not installed') if result.blank?

      result.present?
    end
  end
end
