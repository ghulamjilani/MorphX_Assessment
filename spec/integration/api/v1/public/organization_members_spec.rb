# frozen_string_literal: true

require 'swagger_helper'

describe 'OrganizationMembers', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/organizations/{organization_id}/organization_members' do
    get 'Get Organization Members info' do
      tags 'Public::OrganizationMembers'
      parameter name: :organization_id, in: :path, type: :string
      parameter name: :scope, in: :query, type: :string, description: 'Possible values: presenters, blog'
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
