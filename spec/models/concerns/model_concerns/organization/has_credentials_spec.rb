# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::Organization::HasCredentials do
  let(:credential) { create(:access_management_credential, code: ::AccessManagement::Credential::Codes::START_SESSION) }
  let(:groups_member) { create(:access_management_organization_groups_member) }
  let(:group) { groups_member.group }
  let(:organization) { group.organization }

  describe '#users_ids_with_credentials' do
    before do
      group.groups_credentials.create!(credential: credential)
    end

    it { expect { organization.users_ids_with_credentials(credential.code) }.not_to raise_error }

    it 'contains user with credential' do
      expect(organization.users_ids_with_credentials(credential.code)).to include(groups_member.organization_membership.user_id)
    end

    it 'contains organization owner' do
      expect(organization.users_ids_with_credentials(credential.code)).to include(organization.user_id)
    end
  end
end
