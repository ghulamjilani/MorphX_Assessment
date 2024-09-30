# frozen_string_literal: true

require 'swagger_helper'

describe '::Im::ChannelConversation', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/im/channel_conversations' do
    get 'All User Channel Conversations' do
      tags 'User::Im::Channel::Conversation'
      description 'Get all conversations with pagination'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
