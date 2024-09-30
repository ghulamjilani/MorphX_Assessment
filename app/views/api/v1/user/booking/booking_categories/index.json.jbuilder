# frozen_string_literal: true

json.array! @booking_categories, partial: 'api/v1/user/booking/booking_categories/booking_category', as: :booking_category
