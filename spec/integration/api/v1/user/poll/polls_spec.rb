# frozen_string_literal: true

require 'swagger_helper'

describe 'Polls', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/poll/poll_templates/{poll_template_id}/polls' do
    get 'All poll' do
      tags 'User::Poll::Polls'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :poll_template_id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end

    post 'Create and attach poll' do
      tags 'User::Poll::Polls'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :poll_template_id, in: :path, type: :string, required: true
      parameter name: :poll, in: :body, schema: {
        type: :object,
        properties: {
          model_id: { type: :integer, required: true },
          model_type: { type: :string, required: true },
          duration: { type: :integer, required: false },
          multiselect: { type: :boolean, required: true },
          manual_stop: { type: :boolean, required: true }
        }
      }
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/poll/poll_templates/{poll_template_id}/polls/{id}' do
    get 'Get poll' do
      tags 'User::Poll::Polls'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :poll_template_id, in: :path, type: :string, required: true
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end

    put 'Update poll' do
      tags 'User::Poll::Polls'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :poll_template_id, in: :path, type: :string, required: true
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :poll, in: :body, schema: {
        type: :object,
        properties: {
          enabled: { type: :boolean, required: true }
        }
      }
      response '200', 'Found' do
        run_test!
      end
    end

    delete 'Delete poll template' do
      tags 'User::Poll::Polls'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :poll_template_id, in: :path, type: :string, required: true
      parameter name: :Authorization, in: :header, type: :string, required: false

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/poll/poll_templates/{poll_template_id}/polls/{poll_id}/vote' do
    post 'Vote' do
      tags 'User::Poll::Polls'
      produces 'application/json'
      parameter name: :poll_id, in: :path, type: :string
      parameter name: :poll_template_id, in: :path, type: :string, required: true
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :option_ids, in: :query, type: :array, required: true, items: { type: :integer }

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
