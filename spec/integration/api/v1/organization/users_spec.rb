# frozen_string_literal: true

require 'swagger_helper'

describe 'Users', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/organization/users' do
    get 'All Users' do
      tags 'Organization::Users'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'id', 'created_at', 'updated_at'. Default: 'created_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/organization/users/{id}' do
    get 'Get User info' do
      tags 'Organization::Users'
      description ''
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :Authorization, in: :header, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/organization/users/' do
    post 'Create User' do
      tags 'Organization::Users'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object, properties: {
              email: { type: :string, example: 'organiztaion-user1@unite.live' },
              password: { type: :string, example: 'password' },
              birthdate: { type: :string, example: '01.01.1990' },
              gender: { type: :string, example: 'male' },
              first_name: { type: :string, example: 'APiTest' },
              last_name: { type: :string, example: 'User' }
            }
          },
          organization_membership: {
            type: :object, properties: {
              role: { type: :string, example: 'administrator' },
              position: { type: :string, example: 'Tech Lead' }
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
