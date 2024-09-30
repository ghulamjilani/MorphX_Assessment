# frozen_string_literal: true

class MindBodyJobs::Staff::AssignUser < ApplicationJob
  sidekiq_options queue: 'low'

  # class schedule has been created or updated
  def perform(staff_id)
    staff = MindBodyDb::Staff.find(staff_id)
    user_id = User.find_by(email: staff.email)&.id
    staff.update(user_id: user_id) if user_id
  rescue StandardError => e
    Airbrake.notify("MindBodyOnline #{e.message}", parameters: {
                      staff_id: staff_id
                    })
  end
end
