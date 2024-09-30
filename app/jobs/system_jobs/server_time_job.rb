# frozen_string_literal: true

module SystemJobs
  class ServerTimeJob < ApplicationJob
    def perform
      time_now = Time.now.utc
      SystemChannel.broadcast 'server_time',
                              {
                                time_now: time_now.to_fs(:rfc3339),
                                time_now_i: time_now.to_i,
                                time_now_ms: (time_now.to_f * 1000).round
                              }
    end
  end
end
