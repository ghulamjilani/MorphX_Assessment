# frozen_string_literal: true

require 'swagger_helper'

describe 'Partner::Subscriptions', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/webhook/partner/subscriptions' do
    post 'Create or update service subscription' do
      tags 'Webhook::Partner::Subscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :plan_id, in: :query, type: :string, required: true
      parameter name: :subscription_id, in: :query, type: :string, required: true
      parameter name: :customer_id, in: :query, type: :string, required: true
      parameter name: :customer_email, in: :query, type: :string, required: true
      parameter name: :status, in: :query, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
