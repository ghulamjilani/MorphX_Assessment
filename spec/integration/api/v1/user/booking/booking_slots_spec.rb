# frozen_string_literal: true

require 'swagger_helper'

describe 'BookingSlots', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/booking/booking_slots' do
    get 'All bookings' do
      tags 'User::Booking::BookingSlots'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :user_id, in: :query, type: :integer, required: false

      response '200', 'Found' do
        run_test!
      end
    end

    post 'Create booking slot' do
      tags 'User::Booking::BookingSlots'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :booking_slot, in: :body, schema: {
        type: :object,
        properties: {
          booking_category_id: { type: :integer, required: true },
          channel_id: { type: :integer, required: true },
          name: { type: :string, required: true },
          description: { type: :string, required: true },
          replay: { type: :boolean, required: true },
          replay_price_cents: { type: :integer },
          currency: { type: :string, example: 'USD' },
          tags: { type: :string },
          slot_rules: { type: :string, required: true },
          week_rules: { type: :string },
          booking_prices_attributes: {
            type: :array,
            items: {
              type: :object,
              properties: {
                duration: { type: :integer, required: true },
                price_cents: { type: :integer, required: true },
                currency: { type: :string, example: 'USD' }
              }
            }
          }
        }
      }
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/booking/booking_slots/{id}' do
    get 'Get booking slot' do
      tags 'User::Booking::BookingSlots'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :Authorization, in: :header, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end

    put 'Update booking slot' do
      tags 'User::Booking::BookingSlots'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string
      parameter name: :booking_slot, in: :body, schema: {
        type: :object,
        properties: {
          booking_category_id: { type: :integer, required: true },
          channel_id: { type: :integer, required: true },
          name: { type: :string, required: true },
          description: { type: :string, required: true },
          replay: { type: :boolean, required: true },
          replay_price_cents: { type: :integer },
          currency: { type: :string, example: 'USD' },
          tags: { type: :string },
          slot_rules: { type: :string, required: true },
          week_rules: { type: :string },
          booking_prices_attributes: {
            type: :array,
            items: {
              type: :object,
              properties: {
                id: { type: :integer },
                duration: { type: :integer, required: true },
                price_cents: { type: :integer, required: true },
                currency: { type: :string, example: 'USD' }
              }
            }
          }
        }
      }
      response '200', 'Found' do
        run_test!
      end
    end

    delete 'Delete booking slot' do
      tags 'User::Booking::BookingSlots'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :Authorization, in: :header, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/booking/booking_slots/{id}/calculate_price' do
    get 'Calculate booking slot price' do
      tags 'User::Booking::BookingSlots'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :price_id, in: :query, type: :integer, required: true
      parameter name: :start_at, in: :query, type: :string, required: true, example: '2001-02-03T04:05:06+07:00'
      parameter name: :end_at, in: :query, type: :string, required: true, example: '2001-02-03T04:05:06+07:00'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/booking/booking_slots/{id}/bookings' do
    get 'Get booking slots bookings per day' do
      tags 'User::Booking::BookingSlots'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :date, in: :query, type: :string, required: false, example: '2023-04-20'
      parameter name: :date_from, in: :query, type: :string, required: false, example: '2023-04-20'
      parameter name: :date_to, in: :query, type: :string, required: false, example: '2023-04-20'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
