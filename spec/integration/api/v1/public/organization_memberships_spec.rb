# frozen_string_literal: true

require 'swagger_helper'

describe 'OrganizationMemberships', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/organization_memberships' do
    get 'Get organization memberships' do
      tags 'Public::OrganizationMemberships'
      parameter name: :organization_id, in: :query, type: :string
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'id', 'created_at', 'updated_at'. Default: 'created_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/public/organizations/{organization_id}/organization_memberships' do
    get 'Get organization memberships' do
      tags 'Public::Organizations'
      parameter name: :organization_id, in: :path, type: :string
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'id', 'created_at', 'updated_at'. Default: 'created_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
