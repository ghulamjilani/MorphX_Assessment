# frozen_string_literal: true

require 'swagger_helper'

describe 'Subscriptions', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/customer/subscriptions' do
    get 'List all user subscriptions' do
      tags 'User::Customer::Subscriptions'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :status, in: :query, type: :string
      parameter name: :channel_id, in: :query, type: :string
      parameter name: :order_by, in: :query, type: :string, description: "Valid values are: 'created_at', 'status', 'canceled_at'. Default: 'created_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
