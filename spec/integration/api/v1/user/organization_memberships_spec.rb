# frozen_string_literal: true

require 'swagger_helper'

describe 'OrganizationMemberships', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/organization_memberships' do
    get 'All OrganizationMemberships of current user' do
      tags 'User::OrganizationMemberships'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :organization_id, in: :query, type: :integer
      parameter name: :status, in: :query, type: :string
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'id', 'created_at', 'updated_at'. Default: 'id'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/organization_memberships/{id}' do
    get 'Get OrganizationMembership info' do
      tags 'User::OrganizationMemberships'
      description ''
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :Authorization, in: :header, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/organization_memberships/{id}' do
    put 'Update OrganizationMembership' do
      tags 'User::OrganizationMemberships'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :status, in: :query, type: :string, description: "Available statuses: #{::OrganizationMembership::Statuses::ALL.map { |s| "'#{s}'" }.join(', ')}"
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
