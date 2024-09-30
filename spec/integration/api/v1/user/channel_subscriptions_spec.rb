# frozen_string_literal: true

require 'swagger_helper'

describe 'ChannelSubscriptions', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/channel_subscriptions' do
    get 'Get all user subscriptions' do
      tags 'User::ChannelSubscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/channel_subscriptions/{id}' do
    get 'Get user subscription' do
      tags 'User::ChannelSubscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/channel_subscriptions' do
    post 'Create new subscription' do
      tags 'User::ChannelSubscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :plan_id, in: :query, type: :integer, required: true
      parameter name: :gift, in: :path, type: :integer, required: false, description: '&gift=1'
      parameter name: :recipient, in: :path, type: :string, required: false, description: 'required if &gift=1'
      parameter name: :stripe_token, in: :path, type: :string, required: true,
                description: 'received from stripe js tok_ or card_ from payment methods list'
      parameter name: :country, in: :path, type: :string, required: true, description: 'eg. US'
      parameter name: :zip_code, in: :path, type: :string, required: true,
                description: 'required for US but lets add it always'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/channel_subscriptions/:id/check_recipient_email' do
    post 'Check user by email for gift subscription' do
      tags 'User::ChannelSubscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :email, in: :query, type: :string, required: true, description: '&email=example@email.com'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
