# frozen_string_literal: true

require 'swagger_helper'

describe 'ConnectAccounts', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/payouts/payout_methods/{payout_method_id}/connect_accounts' do
    post 'Create connect account for payout method' do
      tags 'User::Payouts::ConnectAccounts'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :payout_method_id, type: :string, in: :path
      parameter name: :account_info, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, example: 'user@example.com', required: true },
          business_website: { type: :string, example: 'https://example.com', required: true },
          mcc: { type: :string, example: '7623', enum: ::MerchantCategory.all.pluck(:mcc), required: true },
          first_name: { type: :string, example: 'John', required: true },
          last_name: { type: :string, example: 'Doe', required: true },
          date_of_birth: { type: :string, example: '03/22/2000', required: true },
          ssn_last_4: { type: :string, example: '0000', required: true }, # rubocop:disable Naming/VariableNumber
          phone: { type: :string, example: '+15555550000', required: true },
          address_line_1: { type: :string, example: 'Ololo 24 st', required: true }, # rubocop:disable Naming/VariableNumber
          address_line_2: { type: :string }, # rubocop:disable Naming/VariableNumber
          city: { type: :string, required: true },
          state: { type: :string, example: 'AK' },
          zip: { type: :string },
          country: { type: :string, example: 'US' }
        }
      }
      parameter name: :passport_file, in: :formData, type: :file
      parameter name: :additional_document_file, in: :formData, type: :file

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/payouts/payout_methods/{payout_method_id}/connect_accounts/{id}' do
    put 'Update connect account' do
      tags 'User::Payouts::ConnectAccounts'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :string
      parameter name: :payout_method_id, type: :string, in: :path
      parameter name: :account_info, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, example: 'user@example.com', required: true },
          business_website: { type: :string, example: 'https://example.com', required: true },
          mcc: { type: :string, example: '7623', enum: ::MerchantCategory.all.pluck(:mcc), required: true },
          first_name: { type: :string, example: 'John', required: true },
          last_name: { type: :string, example: 'Doe', required: true },
          date_of_birth: { type: :string, example: '03/22/2000', required: true },
          ssn_last_4: { type: :string, example: '0000', required: true }, # rubocop:disable Naming/VariableNumber
          phone: { type: :string, example: '+15555550000', required: true },
          address_line_1: { type: :string, example: 'Ololo 24 st', required: true }, # rubocop:disable Naming/VariableNumber
          address_line_2: { type: :string }, # rubocop:disable Naming/VariableNumber
          city: { type: :string, required: true },
          state: { type: :string, example: 'AK' },
          zip: { type: :string, required: true },
          country: { type: :string, example: 'US', required: true }
        }
      }
      parameter name: :passport_file, in: :formData, type: :file
      parameter name: :additional_document_file, in: :formData, type: :file

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
