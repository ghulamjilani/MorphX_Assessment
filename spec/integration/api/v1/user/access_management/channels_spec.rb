# frozen_string_literal: true

require 'swagger_helper'

describe 'Channels', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/access_management/channels' do
    get 'All credentials' do
      tags 'User::AccessManagement::Channels'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :permission_code, in: :query, type: :string, description: 'eg. create_session'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
