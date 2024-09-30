# frozen_string_literal: true

require 'swagger_helper'

describe 'Channels', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/organization/partner/subscriptions' do
    get 'All Partner Subscriptions' do
      tags 'Organization::Partner::Subscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :foreign_subscription_id, in: :query, type: :string, required: false
      parameter name: :partner_plan_id, in: :query, type: :string, required: false
      parameter name: :free_subscription_id, in: :query, type: :string, required: false
      parameter name: :foreign_customer_email, in: :query, type: :string, required: false
      parameter name: :order, in: :query, type: :string, required: false, description: 'asc, desc'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
