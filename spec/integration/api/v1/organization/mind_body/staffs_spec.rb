# frozen_string_literal: true

require 'swagger_helper'

describe 'Staffs', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/organization/mind_body/staffs/{id}' do
    get 'Get Staff' do
      tags 'Organization::MindBody::Staffs'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/organization/mind_body/staffs/{id}' do
    put 'Update Staff' do
      tags 'Organization::MindBody::Staffs'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer
      parameter name: :user_id, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
