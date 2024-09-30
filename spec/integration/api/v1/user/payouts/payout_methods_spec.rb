# frozen_string_literal: true

require 'swagger_helper'

describe 'PayoutMethods', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/payouts/payout_methods' do
    get 'Payout methods for current organization' do
      tags 'User::Payouts::PayoutMethods'
      description 'Get all payout methods for current user organization'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/payouts/payout_methods' do
    post 'Create payout method' do
      tags 'User::Payouts::PayoutMethods'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :payout_method, in: :body, schema: {
        type: :object,
        properties: {
          business_type: { type: :string, example: 'My first group' },
          provider: { type: :string, example: 'stripe', enum: ['stripe'] },
          country: { type: :string, example: 'US', enum: ::Payouts::Countries::ALL.keys }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/payouts/payout_methods/{id}' do
    put 'Update payout method' do
      tags 'User::Payouts::PayoutMethods'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :string
      parameter name: :accept_tos, in: :query, type: :boolean, example: true
      parameter name: :default, in: :query, type: :boolean, example: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/payouts/payout_methods/{id}' do
    delete 'Delete payout method' do
      tags 'User::Payouts::PayoutMethods'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :string

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
