# frozen_string_literal: true

require 'swagger_helper'

describe 'AccessTokens', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/webrtcservice/chat/access_tokens' do
    post 'Create webrtcservice chat access token' do
      tags 'User::Webrtcservice::Chat::AccessTokens'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :user_type, in: :query, type: :string, required: false, example: 'User',
                description: "Valid values are: 'User', 'ChatMember'"
      parameter name: :identity, in: :query, type: :string, example: '1'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
