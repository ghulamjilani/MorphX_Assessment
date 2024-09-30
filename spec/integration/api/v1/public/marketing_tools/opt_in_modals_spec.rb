# frozen_string_literal: true

require 'swagger_helper'

describe 'OptInModals', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/marketing_tools/opt_in_modals' do
    get 'List all Opt-in Modals' do
      tags 'Public::MarketingTools::OptInModals'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :limit, in: :query, type: :string
      parameter name: :offset, in: :query, type: :string
      parameter name: :order_by, in: :query, type: :string, description: "Valid values are: 'title', 'created_at'. Default: 'title'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :model_type, in: :query, type: :string, required: true, description: "Valid values are: 'Channel', 'Video', 'Recording', 'Session'"
      parameter name: :model_id, in: :query, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/public/marketing_tools/opt_in_modals/{id}/track_view' do
    put 'Track Opt-in Modal view' do
      tags 'Public::MarketingTools::OptInModals'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
