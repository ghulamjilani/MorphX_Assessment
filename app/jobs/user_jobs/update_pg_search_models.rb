# frozen_string_literal: true

class UserJobs::UpdatePgSearchModels < ApplicationJob
  def perform(id)
    user = User.find id
    user.owned_channels.find_each do |channel|
      channel.update_pg_search_document
      channel.update_pg_search_models
    end
    if user.presenter.present?
      Session.where(presenter_id: user.presenter.id)
             .where.not(channel_id: user.owned_channels.pluck(:id)).find_each do |session|
        session.update_pg_search_document
        session.update_pg_search_models
      end
    end
  rescue StandardError => e
    Airbrake.notify("UserJobs::UpdatePgSearchModels #{e.message}", parameters: {
                      id: id
                    })
  end
end
