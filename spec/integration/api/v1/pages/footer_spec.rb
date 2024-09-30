# frozen_string_literal: true

require 'swagger_helper'

describe 'Pages', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/pages/footer' do
    get 'Get footer info' do
      tags 'Pages::Footer'
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
