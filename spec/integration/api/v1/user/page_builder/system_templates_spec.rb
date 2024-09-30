# frozen_string_literal: true

require 'swagger_helper'

describe 'SystemTemplates', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/page_builder/system_templates' do
    get 'List all System Templates' do
      tags 'User::PageBuilder::SystemTemplates'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :limit, in: :query, type: :string
      parameter name: :offset, in: :query, type: :string
      parameter name: :order_by, in: :query, type: :string, description: "Valid values are: 'name', 'created_at'. Default: 'name'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end

    post 'Create System Template' do
      tags 'User::PageBuilder::SystemTemplates'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :name, in: :query, type: :string, required: true
      parameter name: :body, in: :query, type: :string, required: true, description: 'Valid JS object'
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/page_builder/system_templates/template' do
    get 'Show System Template' do
      tags 'User::PageBuilder::SystemTemplates'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :name, in: :query, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end

    delete 'Destroy System Template' do
      tags 'User::PageBuilder::SystemTemplates'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :name, in: :query, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
