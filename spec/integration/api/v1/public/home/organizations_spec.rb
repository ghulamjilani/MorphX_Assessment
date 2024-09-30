# frozen_string_literal: true

require 'swagger_helper'

describe 'Organizations', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/home/organizations' do
    get 'List all organizations for homepage' do
      tags 'Public::Home::Organizations'
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
end
