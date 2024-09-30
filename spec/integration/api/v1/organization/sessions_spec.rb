# frozen_string_literal: true

require 'swagger_helper'

describe 'Sessions', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/organization/sessions' do
    get 'All Sessions' do
      tags 'Organization::Sessions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/organization/sessions/{id}' do
    get 'Get Session' do
      tags 'Organization::Sessions'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/organization/sessions/' do
    post 'Create Session' do
      tags 'Organization::Sessions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          user_id: { type: :integer, example: 2 },
          channel_id: { type: :integer, example: 49 },
          session: {
            type: :object, properties: {
              title: { type: :string, example: 'My first Organization channel' },
              description: { type: :string, example: 'Description' },
              record: { type: :boolean, example: true },
              allow_chat: { type: :boolean, example: true },
              duration: { type: :integer, example: 30 },
              pre_time: { type: :integer, example: 0 },
              autostart: { type: :boolean, example: true },
              device_type: { type: :string, example: 'studio_equipment' },
              service_type: { type: :string, example: 'rtmp' },
              start_at: { type: :datetime, example: '2020-12-01 22:17:32 +0200' },
              ffmpegservice_account_id: { type: :integer, example: 1841 }
            }
          }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/organization/sessions/{id}' do
    put 'Update Session' do
      tags 'Organization::Sessions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :string
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          channel: {
            type: :object, properties: {
              title: { type: :string, example: 'new title' },
              description: { type: :string, example: 'new Description' }
            }
          }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/organization/sessions/{id}' do
    delete 'Delete Session' do
      tags 'Organization::Sessions'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
