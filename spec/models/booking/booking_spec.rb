# frozen_string_literal: true
require 'spec_helper'

describe Booking::Booking do
  describe 'validations' do
    let(:booking_slot) { create(:booking_slot) }
    let(:booking_price) { create(:booking_price, booking_slot: booking_slot, duration: 50, price_cents: 5000) }
    let(:booking) do
      build(:booking,
            booking_slot: booking_slot,
            booking_price: booking_price,
            duration: 50,
            user: create(:user),
            start_at: (DateTime.new(
              Time.now.year,
              Time.now.month,
              Time.now.day,
              10, 0, 0,
              Time.now.in_time_zone(booking_slot.user.timezone).strftime('%:z')
            ) + 1.day),
            end_at: (DateTime.new(
              Time.now.year,
              Time.now.month,
              Time.now.day,
              10, 50, 0,
              Time.now.in_time_zone(booking_slot.user.timezone).strftime('%:z')
            ) + 1.day))
    end
    let(:same_booking) do
      build(:booking,
            booking_slot: booking_slot,
            booking_price: booking_price,
            duration: 50,
            user: create(:user),
            start_at: (DateTime.new(
              Time.now.year,
              Time.now.month,
              Time.now.day,
              10, 0, 0,
              Time.now.in_time_zone(booking_slot.user.timezone).strftime('%:z')
            ) + 1.day),
            end_at: (DateTime.new(
              Time.now.year,
              Time.now.month,
              Time.now.day,
              10, 50, 0,
              Time.now.in_time_zone(booking_slot.user.timezone).strftime('%:z')
            ) + 1.day))
    end
    let(:another_booking) do
      build(:booking,
            booking_slot: booking_slot,
            booking_price: booking_price,
            duration: 50,
            user: create(:user),
            start_at: (DateTime.new(
              Time.now.year,
              Time.now.month,
              Time.now.day,
              11, 0, 0,
              Time.now.in_time_zone(booking_slot.user.timezone).strftime('%:z')
            ) + 1.day),
            end_at: (DateTime.new(
              Time.now.year,
              Time.now.month,
              Time.now.day,
              11, 50, 0,
              Time.now.in_time_zone(booking_slot.user.timezone).strftime('%:z')
            ) + 1.day))
    end
    let(:invalid_booking) do
      build(:booking,
            booking_slot: booking_slot,
            booking_price: booking_price,
            duration: 50,
            user: create(:user),
            start_at: (DateTime.new(
              Time.now.year,
              Time.now.month,
              Time.now.day,
              9, 0, 0,
              Time.now.in_time_zone(booking_slot.user.timezone).strftime('%:z')
            ) + 1.day),
            end_at: (DateTime.new(
              Time.now.year,
              Time.now.month,
              Time.now.day,
              9, 50, 0,
              Time.now.in_time_zone(booking_slot.user.timezone).strftime('%:z')
            ) + 1.day))
    end

    describe 'validate_available_time' do
      it { expect(booking).to be_valid }

      it { expect(invalid_booking).not_to be_valid }
    end

    describe 'validate_booked_time' do
      before { booking.save! }

      it { expect(another_booking).to be_valid }

      it { expect(same_booking).not_to be_valid }
    end
  end
end
