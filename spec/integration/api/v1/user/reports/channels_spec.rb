# frozen_string_literal: true

require 'swagger_helper'

describe 'Channels', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/reports/channels' do
    get 'Channels for reports' do
      tags 'User::Reports::Channels'
      description 'Get all channels for provided organizaion or current user organization'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :organization_ids, in: :query, type: :integer, required: false
      parameter name: :name, in: :query, type: :string, required: false
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
