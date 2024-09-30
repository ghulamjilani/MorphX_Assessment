# frozen_string_literal: true

require 'swagger_helper'

describe 'Contacts', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/contacts' do
    get 'All Contacts' do
      tags 'User::Contacts'
      description 'Get all user contacts'
      produces 'application/json', 'text/csv'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :q, in: :query, type: :string, description: 'Search by name or email'
      parameter name: :ids, in: :query, type: :string, value: 'all', description: 'Array of selected ids OR String value "all"'
      parameter name: :status, in: :query, type: :string,
                description: 'Valid values are: 0..6; All status: , Contacts: 0, Subscription: 1, Unpaid: 2, Canceled: 3, Trial: 4, One time: 5, Opt In: 6'
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
    post 'Create Contact' do
      tags 'User::Contacts'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :email, in: :query, type: :string, required: true, example: 'user_contact@example.com'

      response '200', 'Found' do
        run_test!
      end
    end
    delete 'Delete Contacts' do
      tags 'User::Contacts'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :ids, in: :query, type: :string, required: true, description: 'id, array of ids'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/contacts/{id}' do
    put 'Update Contact' do
      tags 'User::Contacts'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :contact, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, example: 'user_contact@example.com' },
          name: { type: :string, example: 'name' }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/contacts/import_from_csv' do
    post 'Import contacts from csv' do
      tags 'User::Contacts'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :file, in: :formData, type: :file, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/contacts/export_to_csv' do
    post 'Export contacts to csv' do
      tags 'User::Contacts'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :ids, in: :body, type: :array, description: '"all" or array of ids'
      parameter name: :status, in: :body, type: :array, description: '"all" or 0-6 or array of statuses'
      parameter name: :q, in: :body, type: :string

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
