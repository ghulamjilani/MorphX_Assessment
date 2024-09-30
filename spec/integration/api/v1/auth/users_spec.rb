# frozen_string_literal: true

require 'swagger_helper'

describe 'Users', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/auth/users' do
    post 'User authenticate' do
      tags 'Auth::User'
      description 'Use Authorization header from organization if user password is blank'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, example: 'user1@example.com' },
          password: { type: :string, example: 'abcdef' },
          ref_url: { type: :string, example: '/unitedmasters/um-free-game-926?recording_id=177' },
          ref_model: {
            type: :object,
            properties: {
              id: { type: :string, example: '177' },
              type: { type: :string, example: 'Recording' }
            }
          }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/auth/users' do
    delete 'Sign out user' do
      tags 'Auth::User'
      description 'Use Authorization header from organization if user password is blank'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
