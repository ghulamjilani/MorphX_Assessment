# frozen_string_literal: true

require 'swagger_helper'

describe 'SignupTokens', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/signup_tokens' do
    post 'Use Signup Token' do
      tags 'User::SignupTokens'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          signup_token: {
            type: :object,
            properties: {
              token: { type: :string, example: 'abcdefg' }
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
