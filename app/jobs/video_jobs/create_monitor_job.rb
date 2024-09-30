# frozen_string_literal: true

module VideoJobs
  class CreateMonitorJob < ApplicationJob
    def perform
      Session.vod.where("(start_at + (INTERVAL '1 minute' * sessions.duration)) > :check_interval_start AND (start_at + (INTERVAL '1 minute' * sessions.duration)) < :check_interval_end", { check_interval_start: 2.hours.ago.utc, check_interval_end: 1.hour.ago.utc })
             .joins(:room)
             .joins('LEFT JOIN videos on videos.room_id = rooms.id')
             .where(videos: { id: nil }).pluck(:id).each do |session_id|
        send_notification(session_id)
      end
    end

    def send_notification(session_id)
      Airbrake.notify('Video was not created for session with enabled recording', parameters: { session_id: session_id })
    end
  end
end
