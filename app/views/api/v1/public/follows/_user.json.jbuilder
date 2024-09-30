# frozen_string_literal: true

json.cache! model, expires_in: 1.day do
  json.user do
    json.extract! model, :id, :public_display_name, :avatar_url, :relative_path
    json.has_booking_slots model.has_booking_slots?
  end
end
