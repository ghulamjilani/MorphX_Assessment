# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::Booking::BookingSlotsController do
  let(:category) { create(:booking_category) }
  let(:channel) { create(:approved_channel) }
  let(:current_user) { channel.organizer }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }
  let(:valid_attributes) do
    {
      booking_slot: {
        booking_category_id: category.id,
        channel_id: channel.id,
        name: Forgery('name').company_name,
        description: Forgery(:lorem_ipsum).paragraphs(2),
        replay: false,
        replay_price_cents: nil,
        currency: 'USD',
        tags: '[test,test1,test2]',
        slot_rules: '[{"name":"Monday","scheduler":[{"start":"10:00","end":"18:00"}]},{"name":"Tuesday","scheduler":[{"start":"10:00","end":"18:00"}]},{"name":"Wednesday","scheduler":[{"start":"10:00","end":"18:00"}]},{"name":"Thursday","scheduler":[{"start":"10:00","end":"18:00"}]},{"name":"Friday","scheduler":[{"start":"10:00","end":"18:00"}]},{"name":"Saturday","scheduler":[{"start":"10:00","end":"18:00"}]},{"name":"Sunday","scheduler":[{"start":"10:00","end":"18:00"}]}]',
        week_rules: "[#{Time.now.strftime('%-V').to_i},#{(Time.now + 1.week).strftime('%-V').to_i}]",
        booking_prices_attributes: [
          { duration: 15,
            price_cents: 1500,
            currency: 'USD' }
        ]
      }
    }
  end

  let(:invalid_attributes) do
    {
      booking_slot: {
        booking_category_id: nil,
        channel_id: channel.id,
        name: Forgery('name').company_name,
        description: Forgery(:lorem_ipsum).paragraphs(2),
        replay: false,
        replay_price_cents: nil,
        currency: 'USD',
        tags: '[test,test1,test2]',
        slot_rules: '[{"name":"Monday","scheduler":[{"start":"10:00","end":"18:00"}]},{"name":"Tuesday","scheduler":[{"start":"10:00","end":"18:00"}]},{"name":"Wednesday","scheduler":[{"start":"10:00","end":"18:00"}]},{"name":"Thursday","scheduler":[{"start":"10:00","end":"18:00"}]},{"name":"Friday","scheduler":[{"start":"10:00","end":"18:00"}]},{"name":"Saturday","scheduler":[{"start":"10:00","end":"18:00"}]},{"name":"Sunday","scheduler":[{"start":"10:00","end":"18:00"}]}]',
        week_rules: "[#{Time.now.strftime('%-V').to_i},#{(Time.now + 1.week).strftime('%-V').to_i}]",
        booking_prices_attributes: [
          { duration: 10,
            price_cents: 1500,
            currency: 'USD' }
        ]
      }
    }
  end

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    render_views

    describe 'GET /index' do
      it 'renders a successful response' do
        create(:booking_slot, user_id: current_user.id)
        get :index, format: :json
        expect(response).to be_successful
      end
    end

    describe 'GET /show' do
      it 'renders a successful response' do
        booking_slot = create(:booking_slot, user_id: current_user.id)
        get :show, params: { id: booking_slot.id }, format: :json
        expect(response).to be_successful
      end
    end

    describe 'POST /create' do
      context 'with valid parameters' do
        it 'creates a new Booking::BookingSlot' do
          expect do
            post :create, params: valid_attributes, format: :json
          end.to change(Booking::BookingSlot, :count).by(1)
        end
      end

      context 'with invalid parameters' do
        it 'does not create a new Booking::BookingSlot' do
          expect do
            post :create, params: invalid_attributes, format: :json
          end.to change(Booking::BookingSlot, :count).by(0)
        end
      end
    end

    describe 'DELETE /destroy' do
      it 'destroys the requested booking_slot' do
        booking_slot = create(:booking_slot, user_id: current_user.id)
        expect do
          delete :destroy, params: { id: booking_slot.id }, format: :json
        end.to change(Booking::BookingSlot.not_deleted, :count).by(-1)
      end
    end
  end
end
