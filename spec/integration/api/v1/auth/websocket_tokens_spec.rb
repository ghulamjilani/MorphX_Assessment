# frozen_string_literal: true

require 'swagger_helper'

describe 'WebsocketTokens', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/auth/websocket_tokens' do
    post 'Create Websocket Token' do
      tags 'Auth::WebsocketToken'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false, description: 'User or Guest jwt. Optional.'
      parameter name: :visitor_id, in: :query, type: :string, required: true, description: 'Visitor id from cookie. Required.'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
