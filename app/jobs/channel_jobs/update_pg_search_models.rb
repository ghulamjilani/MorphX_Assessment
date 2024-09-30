# frozen_string_literal: true

class ChannelJobs::UpdatePgSearchModels < ApplicationJob
  def perform(id)
    channel = Channel.find id
    channel.sessions.find_each do |session|
      session.update_pg_search_document
      session.update_pg_search_models
    end
    channel.recordings.find_each(&:update_pg_search_document)
  rescue StandardError => e
    Airbrake.notify("ChannelJobs::UpdatePgSearchModels #{e.message}", parameters: {
                      id: id
                    })
  end
end
