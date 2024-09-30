# frozen_string_literal: true

require 'swagger_helper'

describe 'Lists', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/shop/lists' do
    get 'Get all lists of current_user' do
      tags 'Public::Shop::Lists'
      description 'Get all lists'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :model_id, in: :query, type: :integer, required: true
      parameter name: :model_type, in: :query, type: :string, required: true, description: 'Valid values are: Channel, Recording, Session, User, Video'
      parameter name: :order_by, in: :query, type: :string, description: "Valid values are: 'created_at', 'updated_at'. Default: 'updated_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/public/shop/lists/{id}' do
    get 'Get List info' do
      tags 'Public::Shop::Lists'
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
