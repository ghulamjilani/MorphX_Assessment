# frozen_string_literal: true

class MindBodyJobs::Schedules < ApplicationJob
  sidekiq_options queue: 'low'

  def perform(*_args)
    MindBodyDb::Site.find_each do |mbo|
      MindBodyLib::Api::Client.new(credentials: mbo.credentials)
    end
  end
end
