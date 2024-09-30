# frozen_string_literal: true

class ChannelJobs::SlugUpdated < ApplicationJob
  def perform(id)
    channel = Channel.find id
    channel.sessions.find_each do |s|
      s.slug = nil
      s.save
    end
    channel.recordings.find_each(&:update_short_urls)
  rescue StandardError => e
    Airbrake.notify("ChannelJobs::SlugUpdated #{e.message}", parameters: {
                      id: id
                    })
  end
end
