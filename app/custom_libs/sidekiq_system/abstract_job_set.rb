# frozen_string_literal: true

module SidekiqSystem
  class AbstractJobSet
    class << self
      def job_set
        raise NotInheritedError, 'Abstract class method must be overridden'
      end

      def filter(klass)
        job_set.scan("\"class\":\"#{klass}\"")
      end

      def find(klass, *args)
        filter(klass).find do |job|
          job.klass == klass.to_s && job.args.to_s == args.to_s
        end
      end

      def exists?(klass, *args)
        find(klass, *args).present?
      end

      def remove(klass, *args)
        jids = []
        filter(klass).each do |job|
          next unless job.klass == klass.to_s && job.args.to_s == args.to_s

          jids << job.jid
          job.delete
        end

        jids
      end

      def filter_wrapped(wrapped_klass, method_name)
        job_set.scan("\"#{wrapped_klass}\",\"#{method_name}\"")
      end

      # SidekiqSystem::Schedule.find_wrapped(FreeSubscriptionsMailer, 'going_to_be_finished', free_subscription.id)
      def find_wrapped(wrapped_klass, method_name, *args)
        filter_wrapped(wrapped_klass, method_name).find do |job|
          job.item.dig('args', 0, 'arguments', 3, 'args').to_s == args.to_s
        end
      end

      def remove_wrapped(wrapped_klass, method_name, *args)
        jids = []
        filter_wrapped(wrapped_klass, method_name).each do |job|
          next unless job.item.dig('args', 0, 'arguments', 3, 'args').to_s == args.to_s

          jids << job.jid
          job.delete
        end

        jids
      end
    end
  end
end
