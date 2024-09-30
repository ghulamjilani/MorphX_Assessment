# frozen_string_literal: true

json.array! @bookings, partial: 'api/v1/user/booking/bookings/booking', as: :booking
