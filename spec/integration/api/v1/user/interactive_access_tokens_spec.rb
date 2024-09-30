# frozen_string_literal: true

require 'swagger_helper'

describe 'InteractiveAccessTokens', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/interactive_access_tokens' do
    get 'Get list of session access tokens' do
      tags 'User::InteractiveAccessTokens'
      description 'Get list of session access tokens'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :session_id, in: :query, type: :integer, required: true
      parameter name: :individual, in: :query, type: :boolean, required: false,
                description: 'Only single value could be set to true: individual or shared. Individual is checked first'
      parameter name: :shared, in: :query, type: :boolean, required: false,
                description: 'Only single value could be set to true: individual or shared'
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'created_at', 'updated_at'. Default: 'updated_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/interactive_access_tokens/{id}' do
    get 'Get InteractiveAccessToken info' do
      tags 'User::InteractiveAccessTokens'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/interactive_access_tokens' do
    post 'Create InteractiveAccessToken' do
      tags 'User::InteractiveAccessTokens'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :session_id, in: :query, type: :integer, required: true
      parameter name: :individual, in: :query, type: :boolean, required: true,
                description: 'Individual access tokens work only once. Session can have many individual tokens and only one public(non-individual) token.'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/interactive_access_tokens/{id}' do
    put 'Update InteractiveAccessToken' do
      tags 'User::InteractiveAccessTokens'
      description 'Refresh token'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/interactive_access_tokens/{id}' do
    delete 'Delete InteractiveAccessToken' do
      tags 'User::InteractiveAccessTokens'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
