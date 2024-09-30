# frozen_string_literal: true

require 'swagger_helper'

describe 'Channels', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/channels' do
    get 'Get all user channels' do
      tags 'User::Channels'
      description 'Get all user channels'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :status, in: :query, type: :string, required: false,
                description: 'Available values are: "draft", "pending_review", "approved", "rejected"'
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'created_at', 'updated_at'. Default: 'updated_at'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
