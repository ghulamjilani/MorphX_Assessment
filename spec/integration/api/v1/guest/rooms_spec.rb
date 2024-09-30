# frozen_string_literal: true

require 'swagger_helper'

describe 'Rooms', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/guest/rooms' do
    get 'Get running Room info' do
      tags 'Guest::Rooms'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/guest/rooms/room_existence' do
    get 'Check Room existence' do
      tags 'Guest::Rooms'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/guest/rooms/join_interactive_by_token' do
    post 'Join Room by token' do
      tags 'Guest::Rooms'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :token, in: :query, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
