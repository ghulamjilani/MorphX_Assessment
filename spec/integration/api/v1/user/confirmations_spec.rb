# frozen_string_literal: true

require 'swagger_helper'

describe 'Confirmations', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/confirmations' do
    post 'Recend confirmations instructions for current user' do
      tags 'User::Confirmations'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
