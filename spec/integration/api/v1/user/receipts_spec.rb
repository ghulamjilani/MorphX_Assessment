# frozen_string_literal: true

require 'swagger_helper'

describe 'Receipts', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/receipts/{id}' do
    get 'Get Receipt info' do
      tags 'User::Receipts'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/receipts/{id}/mark_as_read' do
    put 'Update receipt attributes' do
      tags 'User::Receipts'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :receipt, in: :body, schema: {
        type: :object,
        properties: {
          is_read: { type: :boolean, example: true },
          trashed: { type: :boolean, example: false },
          deleted: { type: :boolean, example: false }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
