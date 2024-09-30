# frozen_string_literal: true

class FfmpegserviceAccountJobs::SyncTranscoderAuthentication < ApplicationJob
  def perform(id)
    wa = FfmpegserviceAccount.find(id)
    begin
      Sender::Ffmpegservice.client(account: wa).update_transcoder(transcoder: { disable_authentication: !wa.authentication })
    rescue StandardError
      nil
    end
  end
end
