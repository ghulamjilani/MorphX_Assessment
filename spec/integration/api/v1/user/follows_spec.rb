# frozen_string_literal: true

require 'swagger_helper'

describe 'Follows', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/follows' do
    get 'Get all user follows' do
      tags 'User::Follows'
      description 'Get all user follows'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :followable_type, in: :query, type: :string, required: false,
                description: 'Available values are: "User", "Channel", "Organization"'
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'created_at', 'updated_at'. Default: 'updated_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/follows/{id}' do
    get 'Get follow info' do
      tags 'User::Follows'
      description 'Get follow info'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/follows/{id}' do
    get 'Destroy follow' do
      tags 'User::Follows'
      description 'Destroy follow'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/follows' do
    post 'Create new follow' do
      tags 'User::Follows'
      description 'Create new follow'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :followable_id, in: :query, type: :integer, required: true
      parameter name: :followable_type, in: :query, type: :string, required: true,
                description: 'Available values are: "User", "Channel", "Organization"'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/follows/{followable_type}/{followable_id}' do
    get 'Show follow info' do
      tags 'User::Follows'
      description 'Show follow info'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :followable_id, in: :path, type: :integer, required: true
      parameter name: :followable_type, in: :path, type: :string, required: true,
                description: 'Available values are: "User", "Channel", "Organization"'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/follows/{followable_type}/{followable_id}' do
    post 'Create new follow' do
      tags 'User::Follows'
      description 'Create new follow'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :followable_id, in: :path, type: :integer, required: true
      parameter name: :followable_type, in: :path, type: :string, required: true,
                description: 'Available values are: "User", "Channel", "Organization"'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/follows/{followable_type}/{followable_id}' do
    delete 'Destroy follow' do
      tags 'User::Follows'
      description 'Destroy follow'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :followable_id, in: :path, type: :integer, required: true
      parameter name: :followable_type, in: :path, type: :string, required: true,
                description: 'Available values are: "User", "Channel", "Organization"'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
