# frozen_string_literal: true

class MindBodyJobs::Webhook::ClassRoom::CreateUpdate < ApplicationJob
  sidekiq_options queue: 'low'

  # class room has been created or updated
  def perform(event_data)
    remote_id = event_data['classId']
    client = MindBodyLib::Api::ClassRoom.new(credentials: { site_id: event_data['siteId'] })
    data = client.class_rooms({ ClassIds: [remote_id] })[:Classes]
                 .find { |class_room| class_room[:Id] = remote_id }
    data = MindBodyLib::Map.class_room(data)

    raise 'remote_id missing' if data.compact.blank? || data[:remote_id].blank?

    MindBodyDb::ClassRoom.joins(:site).where(mind_body_db_sites: { remote_id: site_remote_id })
                         .find_or_create_by!(remote_id: data[:remote_id]).update!(data.compact)
  rescue StandardError => e
    Airbrake.notify("MindBodyOnline #{e.message}", parameters: {
                      event_data: event_data
                    })
  end
end
