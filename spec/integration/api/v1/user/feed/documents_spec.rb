# frozen_string_literal: true

require 'swagger_helper'

describe 'Documents', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/feed/documents' do
    get 'Get all documents of current_user' do
      tags 'User::Feed::Documents'
      description 'Get all purchased documents of current_user'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :channel_id, in: :query, type: :integer, description: 'Channel ID'
      parameter name: :organization_id, in: :query, type: :integer, description: 'Org ID'
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
