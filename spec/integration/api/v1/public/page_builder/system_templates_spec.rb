# frozen_string_literal: true

require 'swagger_helper'

describe 'SystemTemplates', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/page_builder/system_templates/template' do
    get 'Show System Template' do
      tags 'Public::PageBuilder::SystemTemplates'
      parameter name: :name, in: :query, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
