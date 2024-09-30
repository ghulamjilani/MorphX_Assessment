# frozen_string_literal: true

require 'swagger_helper'

describe 'Messages', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/im/conversations/{conversation_id}/messages' do
    get 'All conversation messages' do
      tags 'User::Im::Messages'
      description 'Get all conversation messages with pagination'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :conversation_id, in: :path, type: :string, required: true
      parameter name: :created_at_from, in: :query, type: :string
      parameter name: :created_at_to, in: :query, type: :string
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/im/conversations/{conversation_id}/messages' do
    post 'Create Message' do
      tags 'User::Im::Messages'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :conversation_id, in: :path, type: :string, required: true
      parameter name: :message, in: :body, required: true, schema: {
        type: :object,
        required: [:body],
        properties: {
          body: { type: :text, example: 'Lorem Ipsum Dolores Sit Amet' },
          deleted_at: { type: :datetime, example: '2020-12-01 22:17:32 +0200' }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/im/conversations/{conversation_id}/messages/{id}' do
    put 'Update Message' do
      tags 'User::Im::Messages'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :conversation_id, in: :path, type: :string, required: true
      parameter name: :message, in: :body, required: true, schema: {
        type: :object,
        required: [:body],
        properties: {
          body: { type: :text, example: 'Lorem Ipsum Dolores Sit Amet' }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/im/conversations/{conversation_id}/messages/' do
    delete 'Mark Message as Deleted' do
      tags 'User::Im::Messages'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :conversation_id, in: :path, type: :string, required: true
      parameter name: :id, in: :query, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
