# frozen_string_literal: true

require 'swagger_helper'

describe 'ChannelReviews', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/channels/{channel_id}/channel_reviews' do
    get 'Get Channel Reviews' do
      tags 'Public::ChannelReviews'
      parameter name: :channel_id, in: :path, type: :string
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
