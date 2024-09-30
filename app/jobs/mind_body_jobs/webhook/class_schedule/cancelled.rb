# frozen_string_literal: true

class MindBodyJobs::Webhook::ClassSchedule::Cancelled < ApplicationJob
  sidekiq_options queue: 'low'

  # class schedule has been created or updated
  def perform(event_data)
    remote_id = event_data['classScheduleId']
    site_remote_id = event_data['siteId']

    raise 'remote_id missing' if remote_id.blank? || site_remote_id.blank?

    MindBodyDb::ClassSchedule.joins(:site).find_by(remote_id: remote_id,
                                                   mind_body_db_sites: { remote_id: site_remote_id }).delete
  rescue StandardError => e
    Airbrake.notify("MindBodyOnline #{e.message}", parameters: {
                      event_data: event_data
                    })
  end
end
