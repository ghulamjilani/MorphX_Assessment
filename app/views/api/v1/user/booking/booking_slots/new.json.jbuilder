# frozen_string_literal: true

envelope json, (@status || 200), (@booking_slot.pretty_errors if @booking_slot.errors.present?) do
  json.partial! 'api/v1/user/booking/booking_slots/booking_slot', booking_slot: @booking_slot

  json.channels do
    json.array! @channels do |channel|
      json.id channel.id
      json.title channel.title
      json.logo_url channel.image_gallery_url
      json.slug channel.slug
      json.is_default channel.is_default
    end
  end
end
