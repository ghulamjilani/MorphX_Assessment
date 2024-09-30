# frozen_string_literal: true

require 'swagger_helper'

describe 'OptInModals', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/marketing_tools/opt_in_modals' do
    get 'List all Opt-in Modals' do
      tags 'User::MarketingTools::OptInModals'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :limit, in: :query, type: :string
      parameter name: :offset, in: :query, type: :string
      parameter name: :order_by, in: :query, type: :string, description: "Valid values are: 'title', 'created_at'. Default: 'title'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :model_type, in: :query, type: :string, description: "Valid values are: 'Channel', 'Video', 'Recording', 'Session'"
      parameter name: :model_id, in: :query, type: :string, description: 'Required if model_type provided'
      parameter name: :active, in: :query, type: :boolean, description: 'Valid values are: 1, 0, true, false, t, f'
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end

    post 'Create Opt-in Modal' do
      tags 'User::MarketingTools::OptInModals'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :title, in: :query, type: :string, required: true
      parameter name: :description, in: :query, type: :string
      parameter name: :active, in: :query, type: :boolean
      parameter name: :trigger_time, in: :query, type: :integer, description: 'In Seconds. Example: 120'
      parameter name: :channel_uuid, in: :query, type: :string, required: true
      parameter name: 'system_template_attributes[name]', in: :query, type: :string, required: true
      parameter name: 'system_template_attributes[body]', in: :query, type: :string, required: true, description: 'Valid JS object'
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/marketing_tools/opt_in_modals/{id}' do
    get 'Show Opt-in Modal' do
      tags 'User::MarketingTools::OptInModals'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :id, in: :path, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end

    put 'Update Opt-in Modal' do
      tags 'User::MarketingTools::OptInModals'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :title, in: :query, type: :string
      parameter name: :description, in: :query, type: :string
      parameter name: :active, in: :query, type: :boolean
      parameter name: :trigger_time, in: :query, type: :integer, description: 'In Seconds. Example: 120'
      parameter name: :channel_uuid, in: :query, type: :string
      parameter name: 'system_template_attributes[name]', in: :query, type: :string
      parameter name: 'system_template_attributes[body]', in: :query, type: :string, description: 'Valid JS object'
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end

    delete 'Destroy Opt-in Modal' do
      tags 'User::MarketingTools::OptInModals'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :id, in: :path, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
