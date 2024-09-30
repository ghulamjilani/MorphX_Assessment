# frozen_string_literal: true

require 'swagger_helper'

describe 'OrganizationMemberships', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/access_management/organizations/{organization_id}/organization_memberships' do
    get 'All OrganizationMemberships for organization' do
      tags 'User::AccessManagement::OrganizationMemberships'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :organization_id, in: :path, type: :integer, required: true
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'id', 'created_at', 'updated_at'. Default: 'id'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/access_management/organizations/{organization_id}/organization_memberships/{id}' do
    get 'Get OrganizationMembership info' do
      tags 'User::AccessManagement::OrganizationMemberships'
      description ''
      produces 'application/json'
      parameter name: :organization_id, in: :path, type: :integer, required: true
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :Authorization, in: :header, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/access_management/organizations/{organization_id}/organization_memberships' do
    post 'Create OrganizationMembership' do
      tags 'User::AccessManagement::OrganizationMemberships'
      description ''
      produces 'application/json'
      parameter name: :organization_id, in: :path, type: :integer, required: true
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :email, in: :query, type: :string
      parameter name: :first_name, in: :query, type: :string
      parameter name: :last_name, in: :query, type: :string
      parameter name: :user_id, in: :query, type: :integer
      parameter name: :group_ids, in: :query, type: :array, items: { type: :integer }, required: true
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/access_management/organizations/{organization_id}/organization_memberships/{id}' do
    put 'Update OrganizationMembership' do
      tags 'User::AccessManagement::OrganizationMemberships'
      produces 'application/json'
      parameter name: :organization_id, in: :path, type: :integer, required: true
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :group_ids, in: :query, type: :array, items: { type: :integer }
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/access_management/organizations/{organization_id}/organization_memberships/{id}' do
    delete 'Destroy OrganizationMembership' do
      tags 'User::AccessManagement::OrganizationMemberships'
      produces 'application/json'
      parameter name: :organization_id, in: :path, type: :integer, required: true
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :Authorization, in: :header, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/access_management/organizations/{organization_id}/organization_memberships/import_from_csv' do
    post 'Import OrganizationMembership' do
      tags 'User::AccessManagement::OrganizationMemberships'
      description ''
      produces 'application/json'
      parameter name: :organization_id, in: :path, type: :integer, required: true
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :file, in: :formData, type: :file, required: true
      parameter name: :groups, in: :query, type: :string, description: '[{"group_id":"3","channel_ids":[]},{"group_id":"4","channel_ids":[319]}]'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
