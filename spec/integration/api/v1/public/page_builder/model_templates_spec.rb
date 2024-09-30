# frozen_string_literal: true

require 'swagger_helper'

describe 'ModelTemplates', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/page_builder/model_templates/template' do
    get 'Show Model Template' do
      tags 'Public::PageBuilder::ModelTemplates'
      parameter name: :model_id, in: :query, type: :string, required: true
      parameter name: :model_type, in: :query, type: :string, required: true, description: "Valid values are: 'User', 'Channel', 'Organization'"
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
