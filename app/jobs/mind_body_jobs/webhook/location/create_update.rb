# frozen_string_literal: true

class MindBodyJobs::Webhook::Location::CreateUpdate < ApplicationJob
  sidekiq_options queue: 'low'

  # location created/updated
  def perform(event_data)
    remote_id = event_data['locationId']
    site_remote_id = event_data['siteId']
    client = MindBodyLib::Api::Location.new(credentials: { site_id: site_remote_id })
    data = client.locations[:Locations]
                 .find { |location| location[:Id] = remote_id }
    data = MindBodyLib::Map.location(data)

    raise 'remote_id missing' if data.compact.blank? || data[:remote_id].blank?

    MindBodyDb::Location.joins(:site).where(mind_body_db_sites: { remote_id: site_remote_id })
                        .find_or_create_by!(remote_id: data[:remote_id]).update!(data.compact)
  rescue StandardError => e
    Airbrake.notify("MindBodyOnline #{e.message}", parameters: {
                      event_data: event_data
                    })
  end
end
