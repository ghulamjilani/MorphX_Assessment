# frozen_string_literal: true

require 'swagger_helper'

describe 'ChannelMembers', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/channels/{channel_id}/channel_members' do
    get 'Get Channel Members info' do
      tags 'Public::ChannelMembers'
      parameter name: :channel_id, in: :path, type: :string
      parameter name: :scope, in: :query, type: :string, description: 'Possible values: presenters, blog'
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
