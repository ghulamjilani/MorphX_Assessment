# frozen_string_literal: true

require 'swagger_helper'

describe 'Blog::Posts', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/blog/posts' do
    get 'All posts' do
      tags 'Blog::Posts'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :resource_type, in: :query, type: :string, required: false,
                description: 'Available values are: "User", "Channel", "Organization"'
      parameter name: :resource_id, in: :query, type: :string, required: false
      parameter name: :resource_slug, in: :query, type: :string, required: false
      parameter name: :status, in: :query, type: :string, required: false,
                description: "Available statuses are: #{Blog::Post::Statuses::ALL.join(', ')}. For statuses other than published Authorization is required."
      parameter name: :date_from, in: :query, type: :string, required: false
      parameter name: :date_to, in: :query, type: :string, required: false
      parameter name: :scope, in: :query, type: :string, required: false,
                description: "Available scopes are: 'read', 'edit'. Default: 'read'"
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'created_at', 'updated_at', 'published_at'. Default: 'created_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  # path '/api/v1/blog/posts/{resource_type}/{resource_id}' do
  #   get 'All posts' do
  #     tags 'Blog::Posts'
  #     produces 'application/json'

  #     parameter name: :Authorization, in: :header, type: :string, required: false
  #     parameter name: :resource_type, in: :path, type: :string, required: true, description: 'Available values are: "User", "Channel", "Organization"'
  #     parameter name: :resource_id, in: :path, type: :string, required: true
  #     parameter name: :status, in: :query, type: :string, required: false, description: "Available values are: #{Blog::Post::Statuses::ALL.join(', ')}"
  #     parameter name: :date_from, in: :query, type: :string, required: false
  #     parameter name: :date_to, in: :query, type: :string, required: false
  #     parameter name: :order_by, in: :query, type: :string, description: "Valid values are: 'created_at', 'updated_at'. Default: 'updated_at'"
  #     parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
  #     parameter name: :offset, in: :query, type: :integer
  #     parameter name: :limit, in: :query, type: :integer

  #     response '200', 'Found' do
  #       run_test!
  #     end
  #   end
  # end

  path '/api/v1/blog/posts/{id}' do
    get 'Get Post info' do
      tags 'Blog::Posts'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: false,
                description: 'Is required if post status is hidden, draft or archived'
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :slug, in: :query, type: :string, required: false,
                description: 'Set slug to "1" if you pass slug in id param'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/blog/posts' do
    post 'Create new post' do
      tags 'Blog::Posts'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :post, in: :body, required: true, schema: {
        type: :object,
        required: %i[channel_id title body],
        properties: {
          channel_id: { type: :string, example: '1' },
          title: { type: :string, example: 'Hello World!' },
          body: { type: :text, example: 'Lorem Ipsum Dolores Sit Amet' },
          status: { type: :string, example: 'published' },
          tag_list: { type: :string, example: 'Maecenas,ut,massa,quis,augue' }
        }
      }
      parameter name: :image_id, in: :query, type: :array, collectionFormat: :csv, items: { type: :string }
      parameter name: :featured_link_preview_id, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/blog/posts/{id}' do
    put 'Update post' do
      tags 'Blog::Posts'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :slug, in: :query, type: :string, required: false,
                description: 'Set slug to "1" if you pass slug in id param'
      parameter name: :post, in: :body, required: true, schema: {
        type: :object,
        required: %i[channel_id title body],
        properties: {
          channel_id: { type: :string, example: '1' },
          title: { type: :string, example: 'Hello World!' },
          body: { type: :text, example: 'Lorem Ipsum Dolores Sit Amet' },
          status: { type: :string, example: 'published' },
          tag_list: { type: :string, example: 'Maecenas,ut,massa,quis,augue' }
        }
      }
      parameter name: :image_id, in: :query, type: :array, collectionFormat: :csv, items: { type: :string }
      parameter name: :featured_link_preview_id, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/blog/posts/{id}' do
    delete 'Delete Post' do
      tags 'Blog::Posts'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :slug, in: :query, type: :string, required: false,
                description: 'Set slug to "1" if you pass slug in id param'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/blog/posts/{id}/vote' do
    post 'Toggle post like' do
      tags 'Blog::Posts'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :slug, in: :query, type: :string, required: false,
                description: 'Set slug to "1" if you pass slug in id param'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
