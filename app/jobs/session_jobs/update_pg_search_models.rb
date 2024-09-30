# frozen_string_literal: true

class SessionJobs::UpdatePgSearchModels < ApplicationJob
  sidekiq_options queue: :low

  def perform(id)
    session = Session.find id
    session.records.find_each(&:update_pg_search_document)
  rescue StandardError => e
    Airbrake.notify("SessionJobs::UpdatePgSearchModels #{e.message}", parameters: {
                      id: id
                    })
  end
end
