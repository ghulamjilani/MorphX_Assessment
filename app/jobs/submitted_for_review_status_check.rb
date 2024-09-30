# frozen_string_literal: true

class SubmittedForReviewStatusCheck < ApplicationJob
  def perform(channel_id)
    channel = Channel.find_by(id: channel_id)

    if channel&.draft?
      ChannelMailer.draft_channel_reminder(channel_id).deliver_later
    end
  end
end
