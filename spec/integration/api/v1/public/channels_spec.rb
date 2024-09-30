# frozen_string_literal: true

require 'swagger_helper'

describe 'Channels', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/channels' do
    get 'Get channels info' do
      tags 'Public::Channels'
      parameter name: :id, in: :query, type: :array, items: { type: :integer }
      parameter name: :show_on_home, in: :query, type: :string, required: false
      parameter name: :organization_id, in: :query, type: :array, items: { type: :integer }
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'created_at', 'updated_at', 'show_on_home', 'listed_at'. Default: 'created_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
  path '/api/v1/public/channels/{id}' do
    get 'Get channel info' do
      tags 'Public::Channels'
      parameter name: :id, in: :path, type: :string
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
