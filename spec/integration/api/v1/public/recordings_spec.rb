# frozen_string_literal: true

require 'swagger_helper'

describe 'Recordings', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/recordings' do
    get 'Get recording info' do
      tags 'Public::Recordings'
      parameter name: :channel_id, in: :query, type: :integer
      parameter name: :organization_id, in: :query, type: :integer
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'id', 'duration', 'created_at', 'updated_at'. Default: 'created_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :created_at_from, in: :query, type: :string, format: 'date-time'
      parameter name: :created_at_to, in: :query, type: :string, format: 'date-time'
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/public/recordings/{id}' do
    get 'Get recording details' do
      tags 'Public::Recordings'
      parameter name: :id, in: :path, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/public/recordings/{recording_id}/embeds' do
    get 'Get embeds list' do
      tags 'Public::Recordings'
      parameter name: :recording_id, in: :path, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
