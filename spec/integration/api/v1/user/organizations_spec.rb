# frozen_string_literal: true

require 'swagger_helper'

describe 'Organizations', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/organizations' do
    get 'Get all user organizations info' do
      tags 'User::Organizations'
      description 'Get all user organizations info'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/organizations/current' do
    get 'Get current organization info' do
      tags 'User::Organizations'
      description 'Get current organization info'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/organizations/current' do
    put 'Update current organization info' do
      tags 'User::Organizations'
      description 'Update current organization info'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :'frontend-settings', in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, example: 'test' },
          descriptiom: { type: :string, example: 'test' }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/organizations/:id/set_current' do
    post 'Update current organization info' do
      tags 'User::Organizations'
      description 'Update current organization'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :integer, example: '1'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
