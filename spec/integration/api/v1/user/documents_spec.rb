# frozen_string_literal: true

require 'swagger_helper'

describe Api::V1::User::DocumentsController, swagger_doc: 'api/v1/swagger.json' do
  path 'api/v1/user/documents' do
    get 'Get documents' do
      tags 'User::Documents'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :channel_id, in: :query, type: :integer
      parameter name: :visible, in: :query, type: :integer
      parameter name: :dashboard, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path 'api/v1/user/documents/{document_id}' do
    get 'Get document' do
      tags 'User::Documents'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :document_id, in: :path, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path 'api/v1/user/documents/{document_id}/buy' do
    post 'Buy document' do
      tags 'User::Documents'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :document_id, in: :path, type: :string, required: true
      parameter name: :token, in: :query, type: :string, required: true
      parameter name: :country, in: :query, type: :string, required: true
      parameter name: :zip_code, in: :query, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path 'api/v1/user/documents' do
    post 'Create document' do
      tags 'User::Documents'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :channel_id, in: :query, type: :string, required: true
      parameter name: :file, in: :formData, type: :string, required: true
      parameter name: :title, in: :query, type: :string
      parameter name: :description, in: :query, type: :string
      parameter name: :hidden, in: :query, type: :boolean
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path 'api/v1/user/documents/{document_id}' do
    put 'Update document' do
      tags 'User::Documents'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :document_id, in: :path, type: :string, required: true
      parameter name: :title, in: :query, type: :string
      parameter name: :description, in: :query, type: :string
      parameter name: :hidden, in: :query, type: :boolean
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path 'api/v1/user/documents/{document_id}' do
    delete 'Delete document' do
      tags 'User::Documents'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :document_id, in: :path, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
