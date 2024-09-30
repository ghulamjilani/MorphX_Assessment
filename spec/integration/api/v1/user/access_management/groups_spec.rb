# frozen_string_literal: true

require 'swagger_helper'

describe 'Groups', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/access_management/groups' do
    get 'All groups' do
      tags 'User::AccessManagement::Groups'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/access_management/groups/{id}' do
    get 'Get group' do
      tags 'User::AccessManagement::Groups'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/access_management/groups/' do
    post 'Create group' do
      tags 'User::AccessManagement::Groups'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :group, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, example: 'My first group' },
          description: { type: :string, example: 'Description' },
          enabled: { type: :boolean, example: true },
          credential_ids: { type: :array, items: { type: :integer }, example: [1, 2, 3] }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/access_management/groups/{id}' do
    put 'Update group' do
      tags 'User::AccessManagement::Groups'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :string
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, example: 'My first group' },
          enabled: { type: :boolean, example: true },
          description: { type: :string, example: 'Description' },
          credential_ids: { type: :array, items: { type: :integer }, example: [1, 2, 3] }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/access_management/groups/{id}' do
    delete 'Delete group' do
      tags 'User::AccessManagement::Groups'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
