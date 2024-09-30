# frozen_string_literal: true

require 'swagger_helper'

describe 'Registrations', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/auth/registrations' do
    post 'User registration' do
      tags 'Auth::User'
      produces 'application/json'
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              first_name: { type: :string, example: 'John' },
              last_name: { type: :string, example: 'Doe' },
              birthdate: { type: :string, example: '12/08/2000' },
              gender: { type: :string, example: 'male' },
              email: { type: :string, example: 'user1@example.com' },
              password: { type: :string, example: 'abcdef' }
            }
          },
          signup_token: {
            type: :object,
            properties: {
              token: { type: :string, example: 'abcdefg' }
            }
          },
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
end
