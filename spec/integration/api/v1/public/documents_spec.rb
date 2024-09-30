# frozen_string_literal: true

require 'swagger_helper'

describe Api::V1::Public::DocumentsController, swagger_doc: 'api/v1/swagger.json' do
  path 'api/v1/public/documents' do
    get 'Get documents' do
      tags 'Public::Documents'
      parameter name: :channel_id, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path 'api/v1/public/documents/{document_id}' do
    get 'Get document' do
      tags 'Public::Documents'
      parameter name: :document_id, in: :path, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
