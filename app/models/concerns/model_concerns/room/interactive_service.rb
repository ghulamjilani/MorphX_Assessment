# frozen_string_literal: true

module ModelConcerns
  module Room
    module InteractiveService
      extend ActiveSupport::Concern

      def no_presenter_stop_scheduled_cache
        "Room/#{__method__}/#{id}"
      end

      def no_presenter_stop_scheduled_at
        Rails.cache.fetch(no_presenter_stop_scheduled_cache) do
          lambda do
            stop_no_presenter_job = SidekiqSystem::Schedule.find(SessionJobs::StopNoPresenterSession, id)
            return nil if stop_no_presenter_job.blank?

            stop_no_presenter_job.at.utc.to_fs(:rfc3339)
          end.call
        end
      end

      def clear_no_presenter_stop_scheduled_cache
        Rails.cache.delete(no_presenter_stop_scheduled_cache)
      end
    end
  end
end
