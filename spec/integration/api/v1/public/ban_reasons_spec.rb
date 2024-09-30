# frozen_string_literal: true

require 'swagger_helper'

describe 'BanReasons', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/ban_reasons' do
    get 'Get BanReasons list' do
      tags 'Public::BanReasons'

      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'id', 'name', 'created_at', 'updated_at'. Default: 'created_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/public/ban_reasons/{id}' do
    get 'Get BanReason info' do
      tags 'Public::BanReasons'

      parameter name: :id, in: :path, type: :integer, required: true

      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
