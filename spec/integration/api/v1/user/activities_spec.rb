# frozen_string_literal: true

require 'swagger_helper'

describe 'Activities', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/activities' do
    get 'All User Activities' do
      tags 'User::Activities'
      description 'Get all user activities matching specified filters'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :trackable_type, in: :query, type: :string, required: false, example: 'Video',
                description: "Valid values are: 'User', 'Organization', 'Channel', 'Session', 'Video', 'Recording'"
      parameter name: :date_from, in: :query, type: :string, example: '2020-12-09T14:02:15.620Z', format: 'date-time'
      parameter name: :date_to, in: :query, type: :string, example: '2020-12-10T14:02:15.620Z', format: 'date-time'
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'created_at', 'updated_at'. Default: 'updated_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/activities/{id}' do
    get 'Get Activity info' do
      tags 'User::Activities'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/activities/' do
    delete 'Delete Activity/Activities' do
      tags 'User::Activities'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :query, type: :string, required: false
      parameter name: :date_from, in: :query, type: :string, required: false
      parameter name: :date_to, in: :query, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/activities/destroy_all' do
    get 'Clear all user Activities' do
      tags 'User::Activities'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
