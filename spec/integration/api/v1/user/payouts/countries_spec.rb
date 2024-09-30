# frozen_string_literal: true

require 'swagger_helper'

describe 'Countries', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/payouts/countries' do
    get 'Countries list for Payout methods' do
      tags 'User::Payouts::Countries'
      description 'Get all countries for payout methods'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
