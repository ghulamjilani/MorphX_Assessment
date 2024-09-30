# frozen_string_literal: true

require 'swagger_helper'

describe 'NetworkSalesReports', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/reports/network_sales_reports' do
    get 'All Network Sales Reports' do
      tags 'User::Reports::NetworkSalesReports'
      description 'Get all sales reports matching specified filters'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :organization_ids, in: :query, type: :string, required: false, example: '[1,2]', description: 'Array of organization ids'
      parameter name: :channel_ids, in: :query, type: :string, required: false, example: '[1,2]', description: 'Array of channel ids'
      parameter name: :date_from, in: :query, type: :string, example: '2020-12-09T14:02:15.620Z', format: 'date-time'
      parameter name: :date_to, in: :query, type: :string, example: '2020-12-10T14:02:15.620Z', format: 'date-time'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
