# frozen_string_literal: true

module SessionJobs
  class StopNoStreamSessionNotificationJob < ApplicationJob
    def perform(session_id)
      return false unless SidekiqSystem::Schedule.exists?(SessionJobs::StopNoStreamSessionJob, session_id)

      SidekiqSystem::Schedule.remove(SessionJobs::StopNoStreamSessionNotificationJob, session_id)
      Immerss::SessionMultiFormatMailer.new.session_no_stream_stop_scheduled(session_id).deliver
    end
  end
end
