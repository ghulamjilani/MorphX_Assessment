# frozen_string_literal: true

envelope json do
  json.followers do
    json.array! @followers do |follower|
      json.cache! follower, expires_in: 1.day do
        json.extract! follower, :id, :public_display_name, :avatar_url, :relative_path
        json.has_booking_slots follower.has_booking_slots?
      end
    end
  end
end
