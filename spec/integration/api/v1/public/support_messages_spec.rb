# frozen_string_literal: true

require 'swagger_helper'

describe 'SupportMessages', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/support_messages/contact_us' do
    post 'Send Contact Us mail' do
      tags 'Public::SupportMessages'
      parameter name: :name, in: :query, type: :string, required: false
      parameter name: :company, in: :query, type: :string, required: false
      parameter name: :first_name, in: :query, type: :string, required: false
      parameter name: :last_name, in: :query, type: :string, required: false
      parameter name: :email, in: :query, type: :string, required: false
      parameter name: :phone, in: :query, type: :string, required: false
      parameter name: :about, in: :query, type: :string, required: false

      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
