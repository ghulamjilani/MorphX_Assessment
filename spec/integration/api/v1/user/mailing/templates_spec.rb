# frozen_string_literal: true

require 'swagger_helper'

describe 'Email templates', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/mailing/templates' do
    get 'All Email Templates' do
      tags 'User::Mailing::Templates'
      description 'Get email templates'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
