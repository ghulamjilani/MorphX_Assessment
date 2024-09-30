# frozen_string_literal: true

require 'swagger_helper'

describe 'SystemThemes', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/sandbox/system_themes' do
    get 'Get system themes info' do
      tags 'Sandbox::SystemThemes'
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
