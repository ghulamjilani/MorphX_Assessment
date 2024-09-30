# frozen_string_literal: true

require 'swagger_helper'

describe 'Polls', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/poll/polls/{id}' do
    get 'Get poll' do
      tags 'Public::Poll::Polls'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
