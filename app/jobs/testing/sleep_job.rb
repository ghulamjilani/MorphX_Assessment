# frozen_string_literal: true

module Testing
  class SleepJob < ApplicationJob
    def perform(sleep_seconds = nil)
      sleep (sleep_seconds || 60).to_i
    end
  end
end
