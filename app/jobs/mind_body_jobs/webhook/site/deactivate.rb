# frozen_string_literal: true

class MindBodyJobs::Webhook::Site::Deactivate < ApplicationJob
  sidekiq_options queue: 'low'

  # new site approved
  def perform(event_data)
    MindBodyDb::Site.find_by(remote_id: event_data['siteId']).delete
  rescue StandardError => e
    Airbrake.notify("MindBodyOnline #{e.message}", parameters: {
                      event_data: event_data
                    })
  end
end
