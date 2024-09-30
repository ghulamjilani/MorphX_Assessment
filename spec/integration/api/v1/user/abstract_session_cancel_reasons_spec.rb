# frozen_string_literal: true

require 'swagger_helper'

describe 'AbstractSessionCancelReason', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/abstract_session_cancel_reasons' do
    get 'All AbstractSessionCancelReasons' do
      tags 'User::AbstractSessionCancelReasons'

      description 'Get all AbstractSessionCancelReasons'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :limit, in: :query, type: :string
      parameter name: :offset, in: :query, type: :string

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
