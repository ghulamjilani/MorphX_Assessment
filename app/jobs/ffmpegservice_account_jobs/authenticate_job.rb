# frozen_string_literal: true

module FfmpegserviceAccountJobs
  # Disables authentication for all unassigned ffmpegservice accounts where authentication is enabled
  class AuthenticateJob < ApplicationJob
    def perform
      FfmpegserviceAccount.not_assigned.rtmp.find_each(&:authentication_off!)
    end
  end
end
