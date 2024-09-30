# frozen_string_literal: true

class MindBodyJobs::ClassSchedule::AutocreateSession < ApplicationJob
  sidekiq_options queue: 'low'

  # class schedule has been created or updated
  def perform(class_schedule_id)
    class_schedule = MindBodyDb::ClassSchedule.find(class_schedule_id)
    # return if class_schedule.description
  rescue StandardError => e
    Airbrake.notify("MindBodyOnline #{e.message}", parameters: {
                      id: id
                    })
  end
end
