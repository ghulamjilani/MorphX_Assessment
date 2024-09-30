# frozen_string_literal: true

require 'swagger_helper'

describe 'BookingCategories', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/booking/booking_categories' do
    get 'All booking categories' do
      tags 'User::Booking::BookingCategories'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
