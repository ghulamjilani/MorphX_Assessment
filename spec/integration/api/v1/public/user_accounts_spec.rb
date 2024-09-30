# frozen_string_literal: true

require 'swagger_helper'

describe 'Users', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/user_accounts/{id}' do
    get 'Get user account info' do
      tags 'Public::UserAccounts'
      parameter name: :id, in: :path, type: :string
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
