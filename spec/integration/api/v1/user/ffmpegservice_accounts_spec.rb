# frozen_string_literal: true

require 'swagger_helper'

describe 'FfmpegserviceAccounts', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/ffmpegservice_accounts' do
    get 'All FfmpegserviceAccounts' do
      tags 'User::FfmpegserviceAccounts'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :studio_id, in: :query, type: :integer
      parameter name: :studio_room_id, in: :query, type: :integer
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'id', 'custom_name', 'created_at', 'updated_at'. Default: 'created_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/ffmpegservice_accounts/{id}' do
    get 'Get FfmpegserviceAccount info' do
      tags 'User::FfmpegserviceAccounts'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/ffmpegservice_accounts/new' do
    get 'Reserve FfmpegserviceAccount' do
      tags 'User::FfmpegserviceAccounts'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :delivery_method, in: :query, type: :string, required: true, example: 'push',
                description: "Valid values are: 'pull', 'push'"

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/ffmpegservice_accounts/' do
    post 'Assign FfmpegserviceAccount' do
      tags 'User::FfmpegserviceAccounts'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :query, type: :integer, required: true
      parameter name: :custom_name, in: :query, required: true, type: :string, example: 'Room 209 IP camera'
      parameter name: :current_service, in: :query, required: true, type: :string, example: 'main',
                description: "Valid values are: 'main', 'rtmp', 'ipcam'"
      parameter name: :studio_room_id, in: :query, required: false, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/ffmpegservice_accounts/{id}' do
    put 'Update FfmpegserviceAccount' do
      tags 'User::FfmpegserviceAccounts'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :custom_name, in: :query, required: false, type: :string, example: 'new title'
      parameter name: :studio_room_id, in: :query, required: false, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/ffmpegservice_accounts/{id}' do
    delete 'Delete FfmpegserviceAccount' do
      tags 'User::FfmpegserviceAccounts'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/ffmpegservice_accounts/{id}/get_status' do
    get 'Get stream status of FfmpegserviceAccount' do
      tags 'User::FfmpegserviceAccounts'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
