# frozen_string_literal: true

require 'swagger_helper'

describe 'Comments', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/comments' do
    get 'Get model comments' do
      tags 'Public::Comments'
      parameter name: :commentable_type, in: :query, type: :string, required: true,
                description: "Valid values are: 'Organization', 'Channel', 'Session', 'Video', 'Recording', 'Comment'"
      parameter name: :commentable_id, in: :query, type: :integer, required: true
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/public/comments/{commentable_type}/{commentable_id}' do
    get 'Get model comments' do
      tags 'Public::Comments'
      parameter name: :commentable_type, in: :path, type: :string, required: true,
                description: "Valid values are: 'Organization', 'Channel', 'Session', 'Video', 'Recording', 'Comment'"
      parameter name: :commentable_id, in: :path, type: :integer, required: true
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
