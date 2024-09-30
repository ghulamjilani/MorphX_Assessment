# frozen_string_literal: true

require 'swagger_helper'

describe 'Credentials', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/access_management/credentials' do
    get 'All credentials' do
      tags 'User::AccessManagement::Credentials'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
