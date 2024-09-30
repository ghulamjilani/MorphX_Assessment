# frozen_string_literal: true

require 'swagger_helper'

describe 'Api::V1::User::UserSearchController', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/user_search' do
    get 'Search user by name or email' do
      tags 'User::UserSearch'
      description 'Search user by name or email'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :query, in: :query, type: :string
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'id', 'display_name', 'created_at', 'updated_at'. Default: 'created_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
