# frozen_string_literal: true

require 'swagger_helper'

describe 'States', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/payouts/states' do
    get 'States list by country for Payout methods' do
      tags 'User::Payouts::States'
      description 'Get all country states for payout methods'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :country_code, in: :query, type: :string, example: 'US', required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
