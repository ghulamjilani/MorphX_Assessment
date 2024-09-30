# frozen_string_literal: true

require 'swagger_helper'

describe 'Conversations', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/conversations' do
    get 'All User Conversations' do
      tags 'User::Conversations'
      description 'Get all user conversations matching specified filters'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :box, in: :query, type: :string,
                description: "Valid values are: 'inbox', 'sentbox', 'trash', 'conversations'. Default: 'conversations'"
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

  path '/api/v1/user/conversations/{id}' do
    get 'Get Conversation info' do
      tags 'User::Conversations'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/conversations/{id}/mark_as_read' do
    post 'Mark all conversation receipts as read' do
      tags 'User::Conversations'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/conversations/{id}/mark_as_unread' do
    post 'Mark all conversation receipts as unread' do
      tags 'User::Conversations'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/conversations/' do
    delete 'Delete Conversation/Conversations' do
      tags 'User::Conversations'
      description 'Mark conversation receipts as deleted'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :query, type: :string, required: false
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
