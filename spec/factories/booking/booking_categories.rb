# frozen_string_literal: true
FactoryBot.define do
  factory :booking_category, class: 'Booking::BookingCategory' do
    sequence(:name) { |n| "synthetic-name-#{n} #{Forgery::Name.industry}" }
    description { 'Lorem ipsum' }
  end
  factory :aa_stub_booking_booking_categories, parent: :booking_category
end
