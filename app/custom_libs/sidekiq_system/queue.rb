# frozen_string_literal: true

module SidekiqSystem
  class Queue
    class << self
      def queues
        Sidekiq::Queue.all.reject { |queue| queue.name == 'mailers' }
      end

      def find(klass, *args)
        queues.each do |queue|
          job_enqueued = queue.find do |job|
            job.klass == klass.to_s && job.args.to_s == args.to_s
          end

          return job_enqueued if job_enqueued.present?
        end
        nil
      end

      def exists?(klass, *args)
        find(klass, *args).present?
      end

      def remove(klass, *args)
        jids = []
        queues.each do |queue|
          queue.each do |job|
            next unless job.klass == klass.to_s && job.args.to_s == args.to_s

            jids << job.jid
            job.delete
          end
        end
        jids
      end
    end
  end
end
