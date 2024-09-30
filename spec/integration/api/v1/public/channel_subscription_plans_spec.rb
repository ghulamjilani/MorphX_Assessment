# frozen_string_literal: true

require 'swagger_helper'

describe 'ChannelSubscriptionPlans', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/channels/{channel_id}/channel_subscription_plans' do
    get 'Get Channel Subscription Plans info' do
      tags 'Public::ChannelSubscriptionPlans'
      parameter name: :channel_id, in: :path, type: :string
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
  path '/api/v1/public/channels/{channel_id}/channel_subscription_plans/{id}' do
    get 'Get Plan info' do
      tags 'Public::ChannelSubscriptionPlans'
      parameter name: :channel_id, in: :path, type: :string
      parameter name: :id, in: :path, type: :string
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
