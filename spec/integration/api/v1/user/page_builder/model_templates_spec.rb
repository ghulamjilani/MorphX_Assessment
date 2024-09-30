# frozen_string_literal: true

require 'swagger_helper'

describe 'ModelTemplates', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/page_builder/model_templates' do
    get 'List all Model Templates of organization' do
      tags 'User::PageBuilder::ModelTemplates'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :organization_id, in: :query, type: :string, required: true
      parameter name: :model_id, in: :query, type: :string
      parameter name: :model_type, in: :query, type: :string, description: "Valid values are: 'User', 'Channel', 'Organization'"
      parameter name: :order_by, in: :query, type: :string, description: "Valid values are: 'created_at', 'views_count'. Default: 'views_count'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end

    post 'Create Model Template' do
      tags 'User::PageBuilder::ModelTemplates'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :model_id, in: :query, type: :string, required: true
      parameter name: :model_type, in: :query, type: :string, required: true, description: "Valid values are: 'User', 'Channel', 'Organization'"
      parameter name: :body, in: :query, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end

    delete 'Destroy Model Template' do
      tags 'User::PageBuilder::ModelTemplates'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :model_id, in: :query, type: :string, required: true
      parameter name: :model_type, in: :query, type: :string, required: true, description: "Valid values are: 'User', 'Channel', 'Organization'"
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/page_builder/model_templates/{id}' do
    get 'Show Model Template' do
      tags 'User::PageBuilder::ModelTemplates'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :model_id, in: :query, type: :string, required: true
      parameter name: :model_type, in: :query, type: :string, required: true, description: "Valid values are: 'User', 'Channel', 'Organization'"
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
