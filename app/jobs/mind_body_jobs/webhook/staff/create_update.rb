# frozen_string_literal: true

class MindBodyJobs::Webhook::Staff::CreateUpdate < ApplicationJob
  sidekiq_options queue: 'low'

  # staff updated
  def perform(event_data)
    remote_id = event_data['staffId']
    client = MindBodyLib::Api::Staff.new(credentials: { site_id: event_data['siteId'] })
    data = client.staffs({ StaffIds: [remote_id] })[:StaffMembers]
                 .find { |staff| staff[:Id] = remote_id }
    data = MindBodyLib::Map.staff(data)

    raise 'remote_id missing' if data.compact.blank? || data[:remote_id].blank?

    MindBodyDb::Staff.joins(:site).where(mind_body_db_sites: { remote_id: site_remote_id })
                     .find_or_create_by!(remote_id: data[:remote_id]).update!(data.compact)
  rescue StandardError => e
    Airbrake.notify("MindBodyOnline #{e.message}", parameters: {
                      event_data: event_data
                    })
  end
end
