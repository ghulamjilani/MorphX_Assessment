# frozen_string_literal: true

require 'swagger_helper'

describe 'Comments', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/comments' do
    get 'Get model comments' do
      tags 'User::Comments'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :commentable_type, in: :query, type: :string, required: true,
                description: "Valid values are: 'Organization', 'Channel', 'Session', 'Video', 'Recording'"
      parameter name: :commentable_id, in: :query, type: :integer, required: true
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/comments/{commentable_type}/{commentable_id}' do
    get 'Get model comments' do
      tags 'User::Comments'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :commentable_type, in: :path, type: :string, required: true,
                description: "Valid values are: 'Organization', 'Channel', 'Session', 'Video', 'Recording'"
      parameter name: :commentable_id, in: :path, type: :integer, required: true
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/comments/:id' do
    get 'Show specific comment for model' do
      tags 'User::Comments'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/comments' do
    post 'Create comment for model' do
      tags 'User::Comments'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :comment, in: :body, required: true, schema: {
        type: :object,
        required: [:body],
        properties: {
          commentable_type: { type: :string, example: 'Comment',
                              description: "Valid values are: 'Session', 'Video', 'Recording', 'Comment'" },
          commentable_id: { type: :integer, example: '1' },
          body: { type: :text, example: 'Lorem Ipsum Dolores Sit Amet' }
        }
      }
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/comments/:id' do
    put 'Update comment' do
      tags 'User::Comments'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :comment, in: :body, required: true, schema: {
        type: :object,
        required: [:body],
        properties: {
          body: { type: :text, example: 'Lorem Ipsum Dolores Sit Amet' },
          visible: { type: :boolean, example: false, description: 'Available only for moderator' }
        }
      }
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/comments/:id' do
    delete 'Destroy comment' do
      tags 'User::Comments'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
