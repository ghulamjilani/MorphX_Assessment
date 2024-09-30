# frozen_string_literal: true

module SidekiqSystem
  class Workers
    class << self
      def job_running?(klass, *args)
        running_job(klass, *args).present?
      end

      def running_job(klass, *args)
        Sidekiq::Workers.new.find do |_process_id, _thread_id, work|
          work['payload']['class'] == klass.to_s && work['payload']['args'].to_s == args.to_s
        end
      end
    end
  end
end
