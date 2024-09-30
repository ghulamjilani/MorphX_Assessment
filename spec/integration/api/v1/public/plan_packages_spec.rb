# frozen_string_literal: true

require 'swagger_helper'

describe 'PlanPackages', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/plan_packages' do
    get 'Get plan packages info' do
      tags 'Public::PlanPackages'
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
