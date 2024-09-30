# frozen_string_literal: true

require 'swagger_helper'

describe 'User Tokens', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/auth/user_tokens' do
    get 'Refresh Auth User Token' do
      tags 'Auth::User'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true, description: 'Encoded auth token'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
