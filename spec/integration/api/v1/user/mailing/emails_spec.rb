# frozen_string_literal: true

require 'swagger_helper'

describe 'Emails', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/mailing/emails' do
    post 'Send email' do
      tags 'User::Mailing::Emails'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :template_id, in: :query, type: :integer, required: true
      parameter name: :contact_ids, in: :query, type: :array, items: { type: :integer }
      parameter name: :body, in: :query, type: :string, required: true
      parameter name: :subject, in: :query, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/mailing/emails/preview' do
    get 'Get email preview' do
      tags 'User::Mailing::Emails'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :template_id, in: :query, type: :integer, required: true
      parameter name: :contact_ids, in: :query, type: :array, items: { type: :integer }
      parameter name: :body, in: :query, type: :string, required: true
      parameter name: :subject, in: :query, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
