# frozen_string_literal: true

class UpdateUserAgent < ApplicationJob
  def perform(user_id, user_agent, ip_address)
    ua = UserAgent.find_or_initialize_by(user_id: user_id,
                                         value: user_agent,
                                         ip_address: ip_address)

    ua.last_time_used_at = Time.now
    ua.save!
  end
end
