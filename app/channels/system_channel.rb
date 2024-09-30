# frozen_string_literal: true

class SystemChannel < ApplicationCable::Channel
  EVENTS = {
    server_time: 'Broadcast server time to sync frontend and backend time. Data: { time_now: "2022-03-21T15:26:38.649+00:00", time_now_i: "1647876398", time_now_ms: "1647876398649" }'
  }.freeze

  def subscribed
    stream_from 'system_channel'
    stream_for current_user
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
