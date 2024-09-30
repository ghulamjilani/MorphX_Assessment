# frozen_string_literal: true

module FfmpegserviceAccountJobs
  # Renames all livestreams on ffmpegservice for each assigned ffmpegservice account if it's name differs from current name
  class RenameJob < ApplicationJob
    def perform
      FfmpegserviceAccount.assigned.find_each do |wa|
        next if wa.name == wa.transcoder_name

        if Sender::Ffmpegservice.client(account: wa).update_transcoder(transcoder: { name: wa.transcoder_name })
          wa.update_columns(name: wa.transcoder_name)
        end
      end
    end
  end
end
