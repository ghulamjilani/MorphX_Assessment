# frozen_string_literal: true

require 'swagger_helper'

describe 'Notifications', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/notifications' do
    get 'All User Notifications' do
      tags 'User::Notifications'
      description 'Get all user notifications matching specified filters'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :is_read, in: :query, type: :boolean, required: false
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'created_at', 'updated_at'. Default: 'created_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/notifications/{id}' do
    get 'Get Notification info' do
      tags 'User::Notifications'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/notifications/' do
    delete 'Delete Notification/Notifications' do
      tags 'User::Notifications'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: false, description: "id, array of ids or 'all'"

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
