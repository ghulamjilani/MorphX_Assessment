# frozen_string_literal: true

require 'swagger_helper'

describe 'SessionDurations', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/sessions/{session_id}/durations' do
    get 'Get available duration options' do
      tags 'User::Session::Durations'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :session_id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end

    post 'Increase session duration' do
      tags 'User::Session::Durations'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :session_id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end

    delete 'Decrease session duration' do
      tags 'User::Session::Durations'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :session_id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
