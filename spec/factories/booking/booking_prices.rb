# frozen_string_literal: true
FactoryBot.define do
  factory :booking_price, class: 'Booking::BookingPrice' do
    currency { 'USD' }
    price_cents { 1000 }
    duration { 60 }
    association :booking_slot, factory: :booking_slot
  end
  factory :aa_stub_booking_booking_prices, parent: :booking_price
end
