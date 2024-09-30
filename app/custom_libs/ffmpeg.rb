# frozen_string_literal: true

class Ffmpeg
  class << self
    def valid?(url)
      return '' unless installed?

      system("ffmpeg -v error -xerror -i #{url} -f null - 2>&1")
    end

    def installed?
      return true if Rails.env.test? || Rails.env.development?

      result = `dpkg -l | grep ffmpeg 2>&1`
      Airbrake.notify('ffmpeg is not installed') if result.blank?

      result.present?
    end
  end
end
