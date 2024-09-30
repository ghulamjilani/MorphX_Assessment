# frozen_string_literal: true

require 'swagger_helper'

describe 'PaymentTransactions', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/payment_transactions' do
    get 'Get user payment_transactions' do
      tags 'User::PaymentTransactions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer
      parameter name: :purchased_item_id, in: :query, type: :integer
      parameter name: :purchased_item_type, in: :query, type: :string, description: 'eg. StripeDb::ServicePlan'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
