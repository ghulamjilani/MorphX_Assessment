# frozen_string_literal: true

require 'swagger_helper'

describe 'Recordings', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/recordings' do
    get 'Get all recordings uploaded to current user\'s owned channels or purchased by user' do
      tags 'User::Recordings'
      description 'Get all recordings uploaded to current user\'s owned channels or purchased by user'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :recordings_type, in: :query, type: :string,
                description: "Valid values are: 'uploaded', 'purchased'. Default: 'uploaded'"
      parameter name: :channel_id, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'id', 'created_at', 'updated_at'. Default: 'created_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/recordings/{id}' do
    get 'Get recording info' do
      tags 'User::Recordings'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :id, in: :path, type: :string
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
