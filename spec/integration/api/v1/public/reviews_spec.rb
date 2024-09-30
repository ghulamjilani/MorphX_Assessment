# frozen_string_literal: true

require 'swagger_helper'

describe 'Reviews', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/reviews' do
    get 'Get model reviews' do
      tags 'Public::Reviews'
      parameter name: :reviewable_type, in: :query, type: :string, required: true,
                description: "Valid values are: 'Organization', 'Channel', 'Session', 'Video', 'Recording'"
      parameter name: :reviewable_id, in: :query, type: :integer, required: true
      parameter name: :created_at_from, in: :query, type: :string,
                description: 'Example: "2021-09-29T00:00:00.000+00:00"'
      parameter name: :created_at_to, in: :query, type: :string, description: 'Example: "2021-09-30T23:59:59.999+00:00"'
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/public/reviews/{reviewable_type}/{reviewable_id}' do
    get 'Get model reviews' do
      tags 'Public::Reviews'
      parameter name: :reviewable_type, in: :path, type: :string, required: true,
                description: "Valid values are: 'Organization', 'Channel', 'Session', 'Video', 'Recording'"
      parameter name: :reviewable_id, in: :path, type: :integer, required: true
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
