# frozen_string_literal: true

envelope json do
  json.channel_members do
    json.array! @channel_members do |channel_member|
      json.partial! 'api/v1/public/users/user_short', model: channel_member.user
      json.has_booking_slots channel_member.user.has_booking_slots?
      json.booking_available channel_member.user.booking_available?
    end
  end
end
