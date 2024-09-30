# frozen_string_literal: true

require 'swagger_helper'

describe 'Lists', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/shop/lists' do
    get 'Get all lists of current_user' do
      tags 'User::Shop::Lists'
      description 'Get all lists of current_user'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :model_id, in: :query, type: :integer, description: 'Required if model_type present'
      parameter name: :model_type, in: :query, type: :string, description: 'Valid values are: Channel, Recording, Session, User, Video'
      parameter name: :order_by, in: :query, type: :string, description: "Valid values are: 'created_at', 'updated_at'. Default: 'updated_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end

    post 'Create new List' do
      tags 'User::Shop::Lists'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :name, in: :query, type: :string, required: true
      parameter name: :description, in: :query, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/shop/lists/{id}' do
    get 'Get List info' do
      tags 'User::Shop::Lists'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end

    put 'Update List info' do
      tags 'User::Shop::Lists'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :name, in: :query, type: :string, required: false
      parameter name: :description, in: :query, type: :string, required: false
      parameter name: :url, in: :query, type: :string, required: false
      parameter name: :selected, in: :query, type: :boolean, required: false

      response '200', 'Found' do
        run_test!
      end
    end

    delete 'Destroy List' do
      tags 'User::Shop::Lists'
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
