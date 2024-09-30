# frozen_string_literal: true

class MindBodyJobs::Webhook::Site::CreateUpdate < ApplicationJob
  sidekiq_options queue: 'low'

  # new site approved
  def perform(event_data)
    remote_id = event_data['siteId']
    client = MindBodyLib::Api::Site.new
    data = client.sites({ SiteIds: [remote_id] })[:Sites]
                 .find { |site| site[:Id] = remote_id }
    data = MindBodyLib::Map.site(data)

    raise 'remote_id missing' if data.compact.blank? || data[:remote_id].blank?

    site = MindBodyDb::Site.find_by(remote_id: data[:remote_id])
    site&.update!(data.compact)
  rescue StandardError => e
    Airbrake.notify("MindBodyOnline #{e.message}", parameters: {
                      event_data: event_data
                    })
  end
end
