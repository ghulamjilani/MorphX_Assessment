# frozen_string_literal: true

require 'swagger_helper'

describe 'LinkPreviews', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/blog/link_previews' do
    get 'Get all post or comment LinkPreviews' do
      tags 'Blog::LinkPreviews'
      description 'Get all post or comment LinkPreviews'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :resource_type, in: :query, type: :string, required: true,
                description: 'Available values are: "Blog::Post", "Blog::Comment"'
      parameter name: :resource_id, in: :query, type: :string, required: false
      parameter name: :resource_slug, in: :query, type: :string, required: false
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'created_at', 'updated_at'. Default: 'updated_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/blog/link_previews/{id}' do
    get 'Get LinkPreview info' do
      tags 'Blog::LinkPreviews'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/blog/link_previews' do
    post 'New LinkPreview' do
      tags 'Blog::LinkPreviews'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :url, in: :query, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/blog/link_previews/{id}/parse' do
    get 'Force parse LinkPreview info' do
      tags 'Blog::LinkPreviews'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
