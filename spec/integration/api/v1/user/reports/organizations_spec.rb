# frozen_string_literal: true

require 'swagger_helper'

describe 'Organizations', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/reports/organizations' do
    get 'Channels for reports' do
      tags 'User::Reports::Organizations'
      description 'Get all Organizations for current user'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :name, in: :query, type: :string, required: false
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
