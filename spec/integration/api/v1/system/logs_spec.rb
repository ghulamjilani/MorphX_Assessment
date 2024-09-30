# frozen_string_literal: true

require 'swagger_helper'

describe 'System::Logs', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/system/logs' do
    post 'Create log' do
      tags 'System'
      description 'Use Authorization header from organization if user password is blank'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          example: { type: :string, example: 'test test test' }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
