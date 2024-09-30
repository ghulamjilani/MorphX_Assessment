# frozen_string_literal: true

class MindBodyJobs::Webhook::Location::Deactivated < ApplicationJob
  sidekiq_options queue: 'low'

  # location created/updated
  def perform(event_data)
    location_remote_id = event_data['locationId']
    site_remote_id = event_data['siteId']

    raise 'remote_id missing' if location_remote_id.blank? || site_remote_id.blank?

    MindBodyDb::Location.joins(:site).find_by(remote_id: location_remote_id,
                                              mind_body_db_sites: { remote_id: site_remote_id }).delete
  rescue StandardError => e
    Airbrake.notify("MindBodyJobs::Webhook::Location::Deactivated #{e.message}", parameters: {
                      event_data: event_data
                    })
  end
end
