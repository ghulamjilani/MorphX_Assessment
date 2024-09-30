# frozen_string_literal: true

module SidekiqSystem
  class Schedule < AbstractJobSet
    class << self
      def job_set
        @job_set ||= Sidekiq::ScheduledSet.new
      end
    end
  end
end
