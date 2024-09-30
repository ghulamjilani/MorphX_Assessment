# frozen_string_literal: true

class PollJobs::StopPoll < ApplicationJob
  def perform(id)
    poll = ::Poll::Poll.find(id)
    poll.stop!
  rescue StandardError => e
    Airbrake.notify("PollJobs::StopPoll #{e.message}", parameters: {
                      id: id
                    })
  end
end
