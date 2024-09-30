# frozen_string_literal: true

require 'swagger_helper'

describe 'RoleMembers', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/access_management/organizations/{organization_id}/group_members/{id}' do
    put 'Update RoleMember' do
      tags 'User::AccessManagement::GroupMembers'
      produces 'application/json'
      parameter name: :organization_id, in: :path, type: :integer, required: true
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :channel_ids, in: :query, type: :array, items: { type: :integer }
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
