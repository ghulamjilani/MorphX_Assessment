# frozen_string_literal: true

require 'swagger_helper'

describe 'ConnectBankAccounts', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/payouts/payout_methods/{payout_method_id}/connect_bank_accounts' do
    post 'Create connect bank account for payout method' do
      tags 'User::Payouts::ConnectBankAccounts'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :payout_method_id, type: :string, in: :path
      parameter name: :bank_account, in: :body, schema: {
        type: :object,
        properties: {
          routing_number: { type: :string, example: '110000000', required: true },
          account_number: { type: :string, example: '000123456789', required: true },
          currency: { type: :string, example: 'USD', required: true },
          account_holder_name: { type: :string, example: 'John Doe', required: true },
          account_holder_type: { type: :string, example: 'individual', required: true },
          country: { type: :string, example: 'US', required: true }
        }
      }
      parameter name: :account_file, in: :formData, type: :file

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/payouts/payout_methods/{payout_method_id}/connect_bank_accounts/{id}' do
    put 'Update connect account' do
      tags 'User::Payouts::ConnectBankAccounts'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :string
      parameter name: :payout_method_id, type: :string, in: :path
      parameter name: :bank_account, in: :body, schema: {
        type: :object,
        properties: {
          routing_number: { type: :string, example: '110000000', required: true },
          account_number: { type: :string, example: '000123456789', required: true },
          currency: { type: :string, example: 'USD', required: true },
          account_holder_name: { type: :string, example: 'John Doe', required: true },
          account_holder_type: { type: :string, example: 'individual', required: true },
          country: { type: :string, example: 'US', required: true }
        }
      }
      parameter name: :account_file, in: :formData, type: :file

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
