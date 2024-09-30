# frozen_string_literal: true

require 'swagger_helper'

describe 'Products', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/shop/products' do
    get 'Get Products info' do
      tags 'User::Shop::Products'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end

    post 'Create Product or find by url' do
      tags 'User::Shop::Products'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :list_id, in: :query, type: :integer, required: false
      parameter name: :'product[title]', in: :query, type: :string, required: true
      parameter name: :'product[description]', in: :query, type: :string, required: false
      parameter name: :'product[short_description]', in: :query, type: :string, required: true
      parameter name: :'product[url]', in: :query, type: :string, required: true
      parameter name: :'product[price]', in: :query, type: :string, required: true
      parameter name: :'product[specifications]', in: :query, type: :string, required: false
      parameter name: :'product[product_image_attributes][remote_original_url]', in: :query, type: :string, required: false
      parameter name: :'product[product_image_attributes][original]', in: :formData, type: :file, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/shop/products/{id}' do
    get 'Get Product info' do
      tags 'User::Shop::Products'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end

    put 'Update Product info' do
      tags 'User::Shop::Products'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :'product[title]', in: :query, type: :string, required: true
      parameter name: :'product[description]', in: :query, type: :string, required: false
      parameter name: :'product[short_description]', in: :query, type: :string, required: true
      parameter name: :'product[url]', in: :query, type: :string, required: true
      parameter name: :'product[price]', in: :query, type: :string, required: true
      parameter name: :'product[specifications]', in: :query, type: :string, required: false
      parameter name: :'product[product_image_attributes][remote_original_url]', in: :query, type: :string, required: false
      parameter name: :'product[product_image_attributes][original]', in: :formData, type: :file, required: false

      response '200', 'Found' do
        run_test!
      end
    end

    delete 'Delete Product' do
      tags 'User::Shop::Products'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/shop/products/search_by_upc' do
    post 'Search existing product or add a new one by UPC and add it to list and session' do
      tags 'User::Shop::Products'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :barcode, in: :query, type: :string, required: true
      parameter name: :list_id, in: :query, type: :integer, required: false
      parameter name: :session_id, in: :query, type: :integer, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
