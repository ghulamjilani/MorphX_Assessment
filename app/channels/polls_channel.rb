# frozen_string_literal: true

class PollsChannel < ApplicationCable::Channel
  EVENTS = {
    'add-poll': 'Poll added. Data: { users: "all", poll_data: data }',
    'stop-poll': 'Poll disabled for model. Data: { users: "all", poll_id: poll_id }',
    'start-poll': 'Poll enabled for model. Data: { users: "all", poll_id: poll_id }',
    'vote-poll': 'Poll voted. Data: { users: "all", poll_data: data }'
  }.freeze

  def subscribed
    stream_from 'polls_channel'
    stream_for current_user
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
