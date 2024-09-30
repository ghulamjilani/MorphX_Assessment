# frozen_string_literal: true

require 'swagger_helper'

describe 'Blog::Images', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/blog/images' do
    get 'Get images for blog post' do
      tags 'Blog::Images'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :post_id, in: :query, type: :string, required: true
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

  path '/api/v1/blog/posts/{post_id}/images' do
    get 'Get images for blog post' do
      tags 'Blog::Images'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :post_id, in: :path, type: :string, required: true
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

  path '/api/v1/blog/images/{id}' do
    get 'Show image info' do
      tags 'Blog::Images'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/blog/images' do
    post 'Create image' do
      tags 'Blog::Images'
      consumes 'multipart/form-data'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :image, in: :formData, type: :file, required: true
      parameter name: :organization_id, in: :formData, type: :string, required: true
      parameter name: :blog_post_id, in: :formData, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/blog/images/{id}' do
    put 'Update image' do
      tags 'Blog::Images'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :blog_post_id, in: :query, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/blog/images/{id}' do
    delete 'Destroy image' do
      tags 'Blog::Images'
      produces 'application/json'

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
