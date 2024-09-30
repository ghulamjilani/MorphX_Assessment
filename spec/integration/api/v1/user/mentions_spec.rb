# frozen_string_literal: true

require 'swagger_helper'

describe 'Mentions', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/mentions' do
    get 'Get all suggestions for mention' do
      tags 'User::Mentions'
      description 'Get all suggestions for mention by part of user display name'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :query, in: :query, type: :string, required: true,
                description: 'Part of user display name to search by'
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'created_at', 'updated_at', 'slug'. Default: 'slug'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :offset, in: :query, type: :integer, description: 'Default 0'
      parameter name: :limit, in: :query, type: :integer, description: 'Default 15'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
