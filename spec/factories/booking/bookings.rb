# frozen_string_literal: true
FactoryBot.define do
  factory :booking, class: 'Booking::Booking' do
    customer_paid { false }
    duration { 15 }
    start_at { DateTime.new(Time.now.year, Time.now.month, Time.now.day, 10, 0, 0, Time.now.in_time_zone('America/Chicago').strftime('%:z')) + 2.days }
    end_at { DateTime.new(Time.now.year, Time.now.month, Time.now.day, 10, 0, 0, Time.now.in_time_zone('America/Chicago').strftime('%:z')) + 2.days + 15.minutes }
    status { 1 }
    association :booking_slot, factory: :booking_slot
    association :booking_price, factory: :booking_price
    association :session, factory: :private_published_session
    association :user, factory: :user
  end
  factory :aa_stub_booking_bookings, parent: :booking
end
