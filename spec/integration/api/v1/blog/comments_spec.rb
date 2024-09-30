# frozen_string_literal: true

require 'swagger_helper'

describe 'Blog::Comments', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/blog/posts/{post_id}/comments' do
    get 'All post comments' do
      tags 'Blog::Comments'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :post_id, in: :path, type: :string, required: true
      parameter name: :user_id, in: :query, type: :string, required: false
      parameter name: :commentable_type, in: :query, type: :string, required: false,
                description: "Available types: 'Blog::Post', 'Blog::Comment'"
      parameter name: :commentable_id, in: :query, type: :string, required: false
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

  path '/api/v1/blog/comments' do
    get 'All comments' do
      tags 'Blog::Comments'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :post_id, in: :query, type: :string, required: false
      parameter name: :user_id, in: :query, type: :string, required: false
      parameter name: :commentable_type, in: :query, type: :string, required: false,
                description: "Available types: 'Blog::Post', 'Blog::Comment'"
      parameter name: :commentable_id, in: :query, type: :string, required: false
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

  path '/api/v1/blog/comments/{id}' do
    get 'Get comment info' do
      tags 'Blog::Comments'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: false,
                description: 'Is required if post status is hidden or draft'
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/blog/posts/{post_id}/comments' do
    post 'Create new comment' do
      tags 'Blog::Comments'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :post_id, in: :path, type: :string, required: true
      parameter name: :comment, in: :body, required: true, schema: {
        type: :object,
        required: [:body],
        properties: {
          commentable_type: { type: :string, example: 'Blog::Comment' },
          commentable_id: { type: :string, example: '1' },
          body: { type: :text, example: 'Lorem Ipsum Dolores Sit Amet' },
          featured_link_preview_id: { type: :string, example: '1' }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/blog/comments' do
    post 'Create new comment' do
      tags 'Blog::Comments'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :post_id, in: :query, type: :string, required: false
      parameter name: :comment, in: :body, required: true, schema: {
        type: :object,
        required: [:body],
        properties: {
          commentable_type: { type: :string, example: 'Blog::Comment' },
          commentable_id: { type: :string, example: '1' },
          body: { type: :text, example: 'Lorem Ipsum Dolores Sit Amet' },
          featured_link_preview_id: { type: :string, example: '1' }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/blog/comments/{id}' do
    put 'Update comment' do
      tags 'Blog::Comments'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :comment, in: :body, required: true, schema: {
        type: :object,
        required: [:body],
        properties: {
          body: { type: :text, example: 'Lorem Ipsum Dolores Sit Amet' },
          featured_link_preview_id: { type: :string, example: '1' }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/blog/comments/{id}' do
    delete 'Delete comment' do
      tags 'Blog::Comments'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
