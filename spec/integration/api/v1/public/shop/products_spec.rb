# frozen_string_literal: true

require 'swagger_helper'

describe 'Products', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/shop/products' do
    get 'Get all products' do
      tags 'Public::Shop::Products'
      description 'Get all products'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :list_id, in: :query, type: :integer, required: true
      parameter name: :order_by, in: :query, type: :string, description: "Valid values are: 'created_at', 'updated_at'. Default: 'updated_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/public/shop/products/{id}' do
    get 'Get Product info' do
      tags 'Public::Shop::Products'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
