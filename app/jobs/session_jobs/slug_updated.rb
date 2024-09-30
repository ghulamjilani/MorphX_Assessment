# frozen_string_literal: true

class SessionJobs::SlugUpdated < ApplicationJob
  def perform(id)
    session = Session.find id

    session.records.find_each(&:update_short_urls)
  rescue StandardError => e
    Airbrake.notify("SessionJobs::SlugUpdated #{e.message}", parameters: {
                      id: id
                    })
  end
end
