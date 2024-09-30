# frozen_string_literal: true

require 'swagger_helper'

describe 'PollTemplates', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/poll/poll_templates' do
    get 'All poll templates' do
      tags 'User::Poll::PollTemplates'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end

    post 'Create poll template' do
      tags 'User::Poll::PollTemplates'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :poll_template, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, required: false },
          question: { type: :string, required: true },
          options_attributes: { type: :array, required: true, items: {
            type: :object,
            properties: {
              title: { type: :string, required: true },
              position: { type: :integer, required: true }
            }
          } }
        }
      }
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/poll/poll_templates/{id}' do
    get 'Get poll template' do
      tags 'User::Poll::PollTemplates'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end

    put 'Update poll template' do
      tags 'User::Poll::PollTemplates'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :poll_template, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, required: false },
          question: { type: :string, required: true },
          options_attributes: { type: :array, required: true, items: {
            type: :object,
            properties: {
              id: { type: :integer, required: false },
              title: { type: :string, required: true },
              position: { type: :integer, required: true },
              _destroy: { type: :boolean, required: false }
            }
          } }
        }
      }
      response '200', 'Found' do
        run_test!
      end
    end

    delete 'Delete poll template' do
      tags 'User::Poll::PollTemplates'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
