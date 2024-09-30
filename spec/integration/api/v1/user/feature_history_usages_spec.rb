# frozen_string_literal: true

require 'swagger_helper'

describe 'FeatureHistoryUsages', swagger_doc: 'api/v1/swagger.json' do
  path 'api/v1/user/feature_history_usages' do
    get 'Get all FeatureHistoryUsages of current organization of current user' do
      tags 'User::FeatureHistoryUsage'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :code, in: :query, type: :string
      parameter name: :plan_feature_id, in: :query, type: :integer
      parameter name: :feature_usage_id, in: :query, type: :string
      parameter name: :model_id, in: :query, type: :string
      parameter name: :model_type, in: :query, type: :string
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
