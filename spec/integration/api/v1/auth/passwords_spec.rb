# frozen_string_literal: true

require 'swagger_helper'

describe 'Passwords', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/auth/passwords' do
    post 'Send reset instructions' do
      tags 'Auth::User'
      produces 'application/json'
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, example: 'user1@example.com' }
            }
          }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
