# frozen_string_literal: true

require 'swagger_helper'

describe 'Studios', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/studios' do
    get 'All Studios' do
      tags 'User::Studios'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'id', 'name', 'created_at', 'updated_at'. Default: 'created_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/studios/{id}' do
    get 'Get Studio' do
      tags 'User::Studios'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/studios/' do
    post 'Create Studio' do
      tags 'User::Studios'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :studio, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, example: 'Unite 209' },
          description: { type: :string, example: 'Floor 2, Room 209' },
          phone: { type: :string, example: '+123456789012' },
          address: { type: :string, example: 'Metalurgiv 2, Zaporizhzhya 69104, Ukraine' }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/studios/{id}' do
    put 'Update Studio' do
      tags 'User::Studios'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string
      parameter name: :studio, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, example: 'Unite 209' },
          description: { type: :string, example: 'Floor 2, Room 209' },
          phone: { type: :string, example: '+123456789012' },
          address: { type: :string, example: 'Metalurgiv 2, Zaporizhzhya 69104, Ukraine' }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/studios/{id}' do
    delete 'Delete Studio' do
      tags 'User::Studios'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
