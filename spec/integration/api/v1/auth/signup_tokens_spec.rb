# frozen_string_literal: true

require 'swagger_helper'

describe 'SignupTokens', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/auth/signup_tokens/{id}' do
    get 'Validate Signup Token' do
      tags 'Auth::User'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
