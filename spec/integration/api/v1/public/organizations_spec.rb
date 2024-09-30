# frozen_string_literal: true

require 'swagger_helper'

describe 'Organizations', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/organizations' do
    get 'List all organizations' do
      tags 'Public::Organizations'
      parameter name: :show_on_home, in: :query, type: :boolean, required: false
      parameter name: :order_by, in: :query, type: :string, description: "Valid values are: 'created_at', 'views_count'. Default: 'views_count'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      parameter name: :promo_weight, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/public/organizations/{id}' do
    get 'Get organization info' do
      tags 'Public::Organizations'
      parameter name: :id, in: :path, type: :string
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/public/organizations/{id}/default_location' do
    get 'Get organization default_location for current user' do
      tags 'Public::Organizations'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :string
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
