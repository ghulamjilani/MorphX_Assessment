# frozen_string_literal: true

require 'swagger_helper'

describe 'Organizations', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/auth/organizations' do
    post 'Organization authenticate' do
      tags 'Auth::Organization'
      produces 'application/json'
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          secret_key: { type: :string, example: 'abcdef' },
          secret_token: { type: :string, example: 'abcdef' }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
