# frozen_string_literal: true

require 'swagger_helper'

describe 'Follows', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/follows/{follower_type}/{follower_id}' do
    get 'Get followings' do
      tags 'Public::Follows'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :follower_type, in: :path, type: :string, description: 'Only "user" is available at the moment',
                required: true
      parameter name: :follower_id, in: :path, type: :string, required: true
      parameter name: :followable_type, in: :query, type: :string, description: "'User', 'Channel' or 'Organization'"
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
