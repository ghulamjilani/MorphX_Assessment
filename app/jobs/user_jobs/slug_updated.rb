# frozen_string_literal: true

class UserJobs::SlugUpdated < ApplicationJob
  def perform(id)
    user = User.find id
    user.channels.find_each do |c|
      c.slug = nil
      c.save
    end
  rescue StandardError => e
    Airbrake.notify("UserJobs::SlugUpdated #{e.message}", parameters: {
                      id: id
                    })
  end
end
