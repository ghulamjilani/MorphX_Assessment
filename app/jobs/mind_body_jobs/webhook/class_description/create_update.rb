# frozen_string_literal: true

class MindBodyJobs::Webhook::ClassDescription::CreateUpdate < ApplicationJob
  sidekiq_options queue: 'low'

  # class description has been created or updated
  def perform(event_data)
    remote_id = event_data['id']
    site_remote_id = event_data['siteId']
    client = MindBodyLib::Api::ClassDescription.new(credentials: { site_id: site_remote_id })
    data = client.class_descriptions({ ClassDescriptionId: remote_id })[:ClassDescriptions]
                 .find { |class_description| class_description[:Id] = remote_id }
    data = MindBodyLib::Map.class_description(data)

    raise 'remote_id missing' if data.compact.blank? || data[:remote_id].blank?

    MindBodyDb::ClassDescription.joins(:site).where(mind_body_db_sites: { remote_id: site_remote_id })
                                .find_or_create_by!(remote_id: data[:remote_id]).update!(data.compact)
  rescue StandardError => e
    Airbrake.notify("MindBodyOnline #{e.message}", parameters: {
                      event_data: event_data
                    })
  end
end
