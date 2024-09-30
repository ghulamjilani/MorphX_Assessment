# frozen_string_literal: true

require 'swagger_helper'

describe 'Followers', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/followers/{followable_type}/{followable_id}' do
    get 'Get followers' do
      tags 'Public::Followers'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :followable_type, in: :path, type: :string, description: 'User/Channel/Organization',
                required: true
      parameter name: :followable_id, in: :path, type: :string, required: true
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'created_at', 'updated_at'. Default: 'created_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
