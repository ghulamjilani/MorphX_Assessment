# frozen_string_literal: true

require 'swagger_helper'

describe 'Pages', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/pages/header' do
    get 'Get header info' do
      tags 'Pages::Header'
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
