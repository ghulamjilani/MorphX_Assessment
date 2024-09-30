# frozen_string_literal: true

require 'swagger_helper'

describe 'Users', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/users/{id}' do
    get 'Get user info' do
      tags 'Public::Users'
      parameter name: :id, in: :path, type: :string
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/public/users/fetch_avatar' do
    get 'Get user avatar' do
      tags 'Public::Users'
      parameter name: :email, in: :query, type: :string
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/public/users/{id}/creator_info' do
    get 'Get creator info' do
      tags 'Public::Users'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :string
      parameter name: :log_activity, in: :query, type: :string, description: 'Pass 0 to skip saving activity in browsing history'
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
