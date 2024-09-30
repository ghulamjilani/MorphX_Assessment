# frozen_string_literal: true

class OrganizationJobs::SlugUpdated < ApplicationJob
  def perform(id)
    organization = Organization.find id
    organization.channels.find_each do |c|
      c.slug = nil
      c.save
    end
  rescue StandardError => e
    Airbrake.notify("OrganizationJobs::SlugUpdated #{e.message}", parameters: {
                      id: id
                    })
  end
end
