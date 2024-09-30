# frozen_string_literal: true

require 'swagger_helper'

describe 'FeatureUsages', swagger_doc: 'api/v1/swagger.json' do
  path 'api/v1/user/feature_usages' do
    get 'Get all FeatureUsages of current organization of current user' do
      tags 'User::FeatureUsage'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :code, in: :query, type: :string
      parameter name: :plan_feature_id, in: :query, type: :integer
      parameter name: :created_at_from, in: :query, type: :string
      parameter name: :created_at_to, in: :query, type: :string
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
