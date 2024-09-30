# frozen_string_literal: true

require 'swagger_helper'

describe 'ChannelFreeSubscriptions', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/channel_free_subscriptions' do
    get 'Get all user free subscriptions' do
      tags 'User::ChannelFreeSubscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/channel_free_subscriptions/{id}' do
    get 'Get user free subscription' do
      tags 'User::ChannelFreeSubscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
