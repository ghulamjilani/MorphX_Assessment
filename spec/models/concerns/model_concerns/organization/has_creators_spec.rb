# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::Organization::HasCreators do
  let(:credential) { create(:access_management_credential, code: ::AccessManagement::Credential::Codes::START_SESSION) }
  let(:groups_member) { create(:access_management_organization_groups_member) }
  let(:group) { groups_member.group }
  let(:organization) { group.organization }

  describe '#creators_count' do
    before do
      group.groups_credentials.create!(credential: credential)
    end

    it { expect { organization.creators_count }.not_to raise_error }
  end
end
