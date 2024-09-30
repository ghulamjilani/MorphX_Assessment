# frozen_string_literal: true

class MindBodyJobs::Webhook::Staff::Deactivated < ApplicationJob
  sidekiq_options queue: 'low'

  # staff updated
  def perform(event_data)
    remote_id = event_data['staffId']
    site_remote_id = event_data['siteId']

    raise 'remote_id missing' if remote_id.blank? || site_remote_id.blank?

    MindBodyDb::Staff.joins(:site).find_by(remote_id: remote_id,
                                           mind_body_db_sites: { remote_id: site_remote_id }).delete
  rescue StandardError => e
    Airbrake.notify("MindBodyOnline #{e.message}", parameters: {
                      event_data: event_data
                    })
  end
end
