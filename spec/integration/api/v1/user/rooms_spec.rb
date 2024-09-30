# frozen_string_literal: true

require 'swagger_helper'

describe 'Rooms', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/rooms/{id}' do
    get 'Get running Room info' do
      tags 'User::Rooms'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{id}' do
    put 'Update Room(start/stop)' do
      tags 'User::Rooms'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          room: {
            type: :object,
            properties: {
              action: { type: :string, example: 'start' },
              is_screen_share_available: { type: :boolean, example: true },
              recording: { type: :boolean, example: true },
              mic_disabled: { type: :boolean, example: true },
              video_disabled: { type: :boolean, example: true },
              backstage: { type: :boolean, example: true },
              room_members_attributes: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    id: { type: :integer, example: 1, required: false },
                    mic_disabled: { type: :boolean, example: true, required: false },
                    video_disabled: { type: :boolean, example: true, required: false },
                    backstage: { type: :boolean, example: true, required: false },
                    pinned: { type: :boolean, example: true, required: false },
                    banned: { type: :boolean, example: true, required: false },
                    ban_reason_id: { type: :integer, example: 1, required: false }
                  }
                }
              },
              session_attributes: {
                type: :object,
                properties: {
                  id: { type: :integer, example: 1, required: false },
                  allow_chat: { type: :boolean, example: false, required: false }
                }
              }
            }
          }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/join_interactive_by_token' do
    post 'Join Room by token' do
      tags 'User::Rooms'
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
