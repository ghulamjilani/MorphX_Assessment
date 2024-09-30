# frozen_string_literal: true

require 'swagger_helper'

describe 'Statistics', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/statistics' do
    get 'Get current organization info' do
      tags 'User::Statistics'
      description 'Get current organization statistic info'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
