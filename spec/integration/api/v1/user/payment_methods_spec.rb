# frozen_string_literal: true

require 'swagger_helper'

describe 'PaymentMethods', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/payment_methods' do
    get 'Get all user cards' do
      tags 'User::PaymentMethods'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
