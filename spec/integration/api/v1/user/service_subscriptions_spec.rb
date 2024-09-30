# frozen_string_literal: true

require 'swagger_helper'

describe 'ServiceSubscriptions', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/service_subscriptions' do
    get 'Get all service subscriptions' do
      tags 'User::ServiceSubscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/service_subscriptions/{id}' do
    get 'Get subscription' do
      tags 'User::ServiceSubscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/service_subscriptions/current' do
    get 'Get current subscription' do
      tags 'User::ServiceSubscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/service_subscriptions' do
    post 'Create new subscription' do
      tags 'User::ServiceSubscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :plan_id, in: :query, type: :string, required: true, description: 'Plan stripe id'
      parameter name: :trial, in: :query, type: :integer, required: false, description: '&trial=1'
      parameter name: :coupon, in: :query, type: :string, required: false, description: '&coupon=20OFF'
      parameter name: :stripe_token, in: :query, type: :string, required: true,
                description: 'received from stripe js tok_ or card_ from payment methods list'
      parameter name: :stripe_card, in: :query, type: :string, required: false, optional: true,
                description: 'received from cards dropdown'
      parameter name: :country, in: :query, type: :string, required: true, description: 'eg. US'
      parameter name: :zip_code, in: :query, type: :string, required: true,
                description: 'required for US but lets add it always'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/service_subscriptions/{id}' do
    put 'Update (cancel trial) subscription' do
      tags 'User::ServiceSubscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer
      parameter name: :cancel_trial, in: :query, type: :integer, required: true, description: '&cancel_trial=1'
      parameter name: :plan_id, in: :query, type: :integer, required: false, description: 'plan_id to switch subscription to it'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/service_subscriptions/{id}' do
    delete 'Cancel subscription' do
      tags 'User::ServiceSubscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/service_subscriptions/{id}/pay' do
    post 'Manually pay subscription' do
      tags 'User::ServiceSubscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/service_subscriptions/apply_coupon' do
    post 'Apply Coupon to Plan' do
      tags 'User::ServiceSubscriptions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :plan_id, in: :query, type: :string, description: '&plan_id=plan_abcdef'
      parameter name: :coupon, in: :query, type: :string, description: '&coupon=20OFF'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
