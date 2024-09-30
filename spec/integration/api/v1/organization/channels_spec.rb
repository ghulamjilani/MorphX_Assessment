# frozen_string_literal: true

require 'swagger_helper'

describe 'Channels', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/organization/channels' do
    get 'All Channels' do
      tags 'Organization::Channels'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/organization/channels/{id}' do
    get 'Get Channel' do
      tags 'Organization::Channels'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/organization/channels/' do
    post 'Create Channel' do
      tags 'Organization::Channels'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          channel: {
            type: :object, properties: {
              title: { type: :string, example: 'My first Organization channel' },
              description: { type: :string, example: 'Description' }
            }
          }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/organization/channels/{id}' do
    put 'Update Channel' do
      tags 'Organization::Channels'
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

  path '/api/v1/organization/channels/{id}' do
    delete 'Delete Channel' do
      tags 'Organization::Channels'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
