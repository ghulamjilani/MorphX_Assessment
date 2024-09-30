# frozen_string_literal: true

require 'swagger_helper'

describe 'Guests', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/auth/guests' do
    post 'Register Guest, get guest jwt' do
      tags 'Auth::Guest'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false, description: 'Guest jwt'
      parameter name: :visitor_id, in: :query, type: :string, required: true, description: 'visitor_id from cookies'
      parameter name: :public_display_name, in: :query, type: :string, required: true, description: 'Encoded auth token'

      response '200', 'Found' do
        run_test!
      end
    end

    put 'Update guest jwt using guest refresh jwt' do
      tags 'Auth::Guest'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true, description: 'Guest refresh jwt'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
