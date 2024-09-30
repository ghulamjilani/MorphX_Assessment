# frozen_string_literal: true

require 'swagger_helper'

describe 'UsageTokens', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/auth/usage_tokens' do
    post 'Create Usage Token' do
      tags 'Auth::Usage'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false, description: 'Encoded auth token'
      parameter name: :visitor_id, in: :query, type: :string, required: false, description: 'Visitor id from cookie, can be sent in cookie too. Required to be present in query or in cookie.'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
