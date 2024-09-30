# frozen_string_literal: true

require 'swagger_helper'

describe 'Bookings', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/booking/bookings' do
    get 'All bookings' do
      tags 'User::Booking::Bookings'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :date, in: :query, type: :string, required: false, example: '2023-04-20'
      parameter name: :date_from, in: :query, type: :string, required: false, example: '2023-04-20'
      parameter name: :date_to, in: :query, type: :string, required: false, example: '2023-04-20'
      parameter name: :requested_bookings, in: :query, type: :boolean, required: false, example: 'true', description: 'to see my bookings from users'

      response '200', 'Found' do
        run_test!
      end
    end

    post 'Create booking' do
      tags 'User::Booking::Bookings'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :booking, in: :body, schema: {
        type: :object,
        properties: {
          booking_slot_id: { type: :integer, required: true },
          duration: { type: :integer, required: true },
          start_at: { type: :string, required: true, example: '2001-02-03T04:05:06+07:00' },
          end_at: { type: :string, required: true, example: '2001-02-03T04:05:06+07:00' },
          stripe_token: { type: :string, required: false },
          stripe_card: { type: :string, required: false },
          price_cents: { type: :integer, required: true, example: '5000 (50 in cents)' }
        }
      }
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/booking/bookings/{id}' do
    get 'Get booking' do
      tags 'User::Booking::Bookings'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end

    delete 'Delete booking' do
      tags 'User::Booking::Bookings'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
