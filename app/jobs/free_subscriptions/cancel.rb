# frozen_string_literal: true

class FreeSubscriptions::Cancel < ApplicationJob
  def perform(id)
    time_now = Time.now.utc
    FreeSubscription.find(id).update(stopped_at: time_now)
  end
end
