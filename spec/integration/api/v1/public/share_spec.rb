# frozen_string_literal: true

require 'swagger_helper'

describe 'Share', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/share' do
    get 'Share model' do
      tags 'Public::Share'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: false, optional: true
      parameter name: :model_type, in: :query, type: :string,
                description: 'Available options: User, Channel, Session, Video, Recording'
      parameter name: :model_id, in: :query, type: :integer, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/public/share/email' do
    post 'Email Share' do
      tags 'Public::Share'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :model_type, in: :query, type: :string,
                description: 'Available options: User, Channel, Session, Video, Recording, Blog::Post'
      parameter name: :model_id, in: :query, type: :integer, required: true
      parameter name: :subject, in: :query, type: :string, required: true
      parameter name: :body, in: :query, type: :string, required: true
      parameter name: :emails, in: :query, type: :string, description: 'email1@example.com,email2@example.com',
                required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
