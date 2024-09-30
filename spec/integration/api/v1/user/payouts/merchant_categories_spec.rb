# frozen_string_literal: true

require 'swagger_helper'

describe 'MerchantCategories', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/payouts/merchant_categories' do
    get 'Merchant Categories list for Payout methods' do
      tags 'User::Payouts::MerchantCategories'
      description 'Get all Merchant Categories for payout methods'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
