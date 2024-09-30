# frozen_string_literal: true

require 'swagger_helper'

describe 'FreeSubscriptions', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/free_subscriptions' do
    get 'Get all free subscriptions' do
      tags 'User::FreeSubscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/free_subscriptions/new' do
    get 'Get channels list for new subscription' do
      tags 'User::FreeSubscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/free_subscriptions' do
    post 'Create new subscription' do
      tags 'User::FreeSubscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :file, in: :formData, type: :file, description: 'csv file or email'
      parameter name: :email, in: :query, type: :string, description: 'csv file or email'
      parameter name: :channel_id, in: :query, type: :integer, required: true, description: 'channel id'
      parameter name: :months, in: :query, type: :integer, required: true, description: '1, 3, 6, 12'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
