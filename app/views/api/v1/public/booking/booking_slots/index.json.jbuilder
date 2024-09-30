# frozen_string_literal: true

json.array! @booking_slots, partial: 'api/v1/public/booking/booking_slots/booking_slot', as: :booking_slot
