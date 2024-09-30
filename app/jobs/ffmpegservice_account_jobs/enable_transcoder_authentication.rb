# frozen_string_literal: true

class FfmpegserviceAccountJobs::EnableTranscoderAuthentication < ApplicationJob
  def perform(id)
    wa = FfmpegserviceAccount.find(id)
    begin
      Sender::Ffmpegservice.client(account: wa).update_transcoder(transcoder: { disable_authentication: false })
    rescue StandardError
      nil
    end
  end
end
