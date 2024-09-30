# frozen_string_literal: true

require 'swagger_helper'

describe 'InteractiveAccessTokens', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/interactive_access_tokens/{id}' do
    get 'Get InteractiveAccessToken info' do
      tags 'Public::InteractiveAccessTokens'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, required: true, description: 'Token value'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
