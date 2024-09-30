# frozen_string_literal: true

require 'swagger_helper'

describe 'StudioRooms', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/studio_rooms' do
    get 'All Studio Rooms' do
      tags 'User::StudioRooms'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :studio_id, in: :query, type: :integer
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

  path '/api/v1/user/studio_rooms/{id}' do
    get 'Get Studio Room' do
      tags 'User::StudioRooms'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/studio_rooms/' do
    post 'Create Studio Room' do
      tags 'User::StudioRooms'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :studio_id, in: :query, type: :integer, required: true
      parameter name: :studio_room, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, example: 'Unite 209' },
          description: { type: :string, example: 'Floor 2, Room 209' }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/studio_rooms/{id}' do
    put 'Update Studio Room' do
      tags 'User::StudioRooms'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :studio_room, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, example: 'Unite 209' },
          description: { type: :string, example: 'Floor 2, Room 209' }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/studio_rooms/{id}' do
    delete 'Delete Studio Room' do
      tags 'User::StudioRooms'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
