# frozen_string_literal: true

require 'swagger_helper'

describe 'OptInModalSubmits', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/marketing_tools/opt_in_modal_submits' do
    post 'Create Opt-in Modal Submit' do
      tags 'Public::MarketingTools::OptInModalSubmits'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :opt_in_modal_id, in: :query, type: :string, required: true
      parameter name: :data, in: :query, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
