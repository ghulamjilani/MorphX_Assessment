# frozen_string_literal: true

require 'swagger_helper'

describe 'Storage::Record', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/storage/records' do
    get 'List all storage records of organization' do
      tags 'User::Storage::Record'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :model_type, in: :query, type: :string
      parameter name: :model_id, in: :query, type: :string
      parameter name: :relation_type, in: :query, type: :string
      parameter name: :object_type, in: :query, type: :string, description: "Available types: 'ActiveStorage::Attachment', 'Aws::S3::ObjectSummary::Collection'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
