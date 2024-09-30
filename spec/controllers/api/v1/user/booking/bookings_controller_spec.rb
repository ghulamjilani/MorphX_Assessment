# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::Booking::BookingsController do
  let(:current_user) { create(:user) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }
  let(:booking_slot) { create(:booking_slot) }
  let(:booking_price) { create(:booking_price, booking_slot: booking_slot, duration: 15) }
  let(:valid_attributes) do
    {
      booking_slot_id: booking_slot.id,
      price_id: booking_price.id,
      duration: 15,
      start_at: DateTime.new(Time.now.year, Time.now.month, Time.now.day, 10, 0, 0, Time.now.in_time_zone('America/Chicago').strftime('%:z')) + 2.days,
      end_at: DateTime.new(Time.now.year, Time.now.month, Time.now.day, 10, 0, 0, Time.now.in_time_zone('America/Chicago').strftime('%:z')) + 2.days + 15.minutes,
      comment: 'ololo',
      stripe_token: @stripe_test_helper.generate_card_token
    }
  end

  let(:invalid_attributes) do
    {
      booking_slot_id: nil,
      price_id: nil,
      duration: 10,
      start_at: DateTime.new(Time.now.year, Time.now.month, Time.now.day, 10, 0, 0, Time.now.in_time_zone('America/Chicago').strftime('%:z')) + 2.days,
      end_at: DateTime.new(Time.now.year, Time.now.month, Time.now.day, 10, 0, 0, Time.now.in_time_zone('America/Chicago').strftime('%:z')) + 2.days + 10.minutes,
      comment: 'ololo',
      stripe_token: nil
    }
  end

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    render_views

    describe 'GET /index' do
      it 'renders a successful response' do
        create(:booking, user_id: current_user.id)
        get :index, format: :json
        expect(response).to be_successful
      end
    end

    describe 'GET /show' do
      it 'renders a successful response' do
        booking = create(:booking, user_id: current_user.id)
        get :show, params: { id: booking.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST /create' do
      context 'with valid parameters' do
        it 'creates a new Booking::Booking' do
          expect do
            post :create, params: { booking: valid_attributes }, format: :json
          end.to change(Booking::Booking, :count).by(1)
        end
      end

      context 'with invalid parameters' do
        it 'does not create a new Booking::Booking' do
          expect do
            post :create, params: { booking: invalid_attributes }, format: :json
          end.to change(Booking::Booking, :count).by(0)
        end
      end
    end
  end
end
