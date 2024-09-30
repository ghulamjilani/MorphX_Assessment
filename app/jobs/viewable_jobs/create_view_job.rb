# frozen_string_literal: true

module ViewableJobs
  class CreateViewJob < ApplicationJob
    def perform(view_params)
      View.create(view_params)
    rescue StandardError => e
      Airbrake.notify(e.message,
                      parameters: {
                        view_params: view_params
                      })
    end
  end
end
