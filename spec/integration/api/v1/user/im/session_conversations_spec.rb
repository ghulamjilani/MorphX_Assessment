# frozen_string_literal: true

require 'swagger_helper'

describe '::Im::SessionConversation', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/im/sessions/{session_id}/conversation' do
    get 'Get session conversation' do
      tags 'User::Im::Session::Conversation'
      description 'Get session conversation'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false
      parameter name: :session_id, in: :path, type: :integer, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
