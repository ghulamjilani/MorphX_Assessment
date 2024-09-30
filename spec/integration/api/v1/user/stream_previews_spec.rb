# frozen_string_literal: true

require 'swagger_helper'

describe 'StreamPreviews', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/stream_previews' do
    get 'All StreamPreviews' do
      tags 'User::StreamPreviews'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :user_id, in: :query, type: :integer
      parameter name: :ffmpegservice_account_id, in: :query, type: :integer
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are:'id', 'created_at', 'updated_at'. Default: 'created_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/stream_previews/{id}' do
    get 'Get StreamPreview info' do
      tags 'User::StreamPreviews'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/stream_previews/' do
    post 'New StreamPreview' do
      tags 'User::StreamPreviews'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :ffmpegservice_account_id, in: :query, type: :integer, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/stream_previews/{id}' do
    delete 'Stop StreamPreview' do
      tags 'User::StreamPreviews'
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
