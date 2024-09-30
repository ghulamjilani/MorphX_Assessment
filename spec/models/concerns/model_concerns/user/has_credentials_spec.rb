# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::User::HasCredentials do
  let(:credential_code) { AccessManagement::Credential::Codes::ALL.sample }
  let(:access_management_credential) do
    create(:access_management_credential, code: credential_code, is_for_channel: true)
  end
  let(:group_credential) do
    create(:access_management_organizational_groups_credential, credential: access_management_credential)
  end
  let(:group) { group_credential.group }
  let(:organization) { group.organization }
  let(:group_member) do
    create(:access_management_groups_member, group: group,
                                             organization_membership: create(:organization_membership, organization: organization))
  end
  let(:group_member_channel) { create(:access_management_groups_members_channel, groups_member: group_member) }
  let(:organization_membership) { group_member.organization_membership }

  describe '#has_any_organization_credential?' do
    subject { user.has_any_organization_credential?(organization, credential_code) }

    context 'when given organization_owner' do
      let(:organization) { create(:organization) }
      let(:user) { organization.user }

      it { is_expected.to be_truthy }
    end

    context 'when given random user' do
      let(:user) { create(:user) }

      it { is_expected.to be_falsey }
    end

    context 'when given organization member without credential' do
      let(:user) { create(:organization_membership, organization: organization).user }

      it { is_expected.to be_falsey }
    end

    context 'when given organization member with credential' do
      let(:user) { organization_membership.user }

      it { is_expected.to be_truthy }
    end

    context 'when given organization member with channel credential' do
      let(:user) { group_member_channel.groups_member.organization_membership.user }

      it { is_expected.to be_truthy }
    end
  end

  describe '#has_organization_credential?' do
    subject { user.has_organization_credential?(organization, credential_code) }

    context 'when given organization_owner' do
      let(:organization) { create(:organization) }
      let(:user) { organization.user }

      it { is_expected.to be_truthy }
    end

    context 'when given random user' do
      let(:user) { create(:user) }

      it { is_expected.to be_falsey }
    end

    context 'when given organization member without credential' do
      let(:user) { create(:organization_membership, organization: organization).user }

      it { is_expected.to be_falsey }
    end

    context 'when given organization member with credential' do
      let(:user) { organization_membership.user }

      it { is_expected.to be_truthy }
    end

    context 'when given organization member with channel credential' do
      let(:user) { group_member_channel.groups_member.organization_membership.user }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_channel_credential?' do
    subject { user.has_channel_credential?(channel, credential_code) }

    let(:group_member2) do
      create(:access_management_groups_member, group: group,
                                               organization_membership: create(:organization_membership, organization: group.organization))
    end
    let(:group_member_channel) do
      create(:access_management_groups_members_channel, groups_member: group_member2,
                                                        channel: create(:listed_channel, organization: group.organization))
    end
    let(:channel) { group_member_channel.channel }

    context 'when given organization_owner' do
      let(:organization) { channel.organization }
      let(:user) { organization.user }

      it { is_expected.to be_truthy }
    end

    context 'when given random user' do
      let(:user) { create(:user) }

      it { is_expected.to be_falsey }
    end

    context 'when given organization member without credential' do
      let(:user) { create(:organization_membership, organization: organization).user }

      it { is_expected.to be_falsey }
    end

    context 'when given organization member with credential' do
      let(:user) { group_member.user }

      it { is_expected.to be_truthy }
    end

    context 'when given organization member with channel credential' do
      let(:user) { group_member_channel.groups_member.user }

      it { is_expected.to be_truthy }
    end
  end

  describe '#organization_channels_with_credentials' do
    let(:user) { group_member.user }

    it { expect { user.organization_channels_with_credentials(organization, credential_code) }.not_to raise_error }

    context 'when given credential from existing assigned role' do
      let(:channel) { group_member_channel.channel }
      let(:user) { group_member_channel.user }

      it { expect(user.organization_channels_with_credentials(organization, credential_code)).to exist(id: channel.id) }
    end

    context 'when groups member channel with proper credentials exists' do
      let(:channel) { group_member_channel.channel }
      let(:user) { group_member_channel.groups_member.organization_membership.user }

      it { expect(user.organization_channels_with_credentials(organization, credential_code)).to exist(id: channel.id) }
    end

    context 'when groups member with proper credentials exists' do
      let(:channel) { create(:approved_channel, organization: group_member.group.organization) }
      let(:user) { group_member.organization_membership.user }

      it { expect(user.organization_channels_with_credentials(organization, credential_code)).to exist(id: channel.id) }
    end

    context 'when groups member with proper credentials exists but assigned to another channel' do
      let(:channel) { create(:approved_channel, organization: group_member.group.organization) }
      let(:user) { group_member_channel.organization_membership.user }

      it {
        expect(user.organization_channels_with_credentials(organization, credential_code)).not_to exist(id: channel.id)
      }
    end
  end

  describe '#all_channels_with_credentials' do
    let(:user) { group_member_channel.user }

    let(:group_credential2) do
      create(:access_management_organizational_groups_credential, credential: access_management_credential)
    end
    let(:group_credential3) do
      create(:access_management_organizational_groups_credential, credential: access_management_credential)
    end
    let(:group2) { group_credential2.group }
    let(:group3) { group_credential3.group }
    let(:organization2) { group2.organization }
    let(:organization3) { group3.organization }
    let(:group_member2) do
      create(:access_management_groups_member, group: group2,
                                               organization_membership: create(:organization_membership, organization: organization2, user: user))
    end
    let(:group_member3) do
      create(:access_management_groups_member, group: group3,
                                               organization_membership: create(:organization_membership, organization: organization3, user: user))
    end
    let(:channel3) { create(:approved_channel, organization: group_member3.group.organization) }
    let(:group_member_channel2) { create(:access_management_groups_members_channel, groups_member: group_member2) }

    before do
      group_member_channel2
      channel3
    end

    it { expect { user.all_channels_with_credentials(credential_code) }.not_to raise_error }

    it { expect(user.all_channels_with_credentials(credential_code)).to exist(id: group_member_channel.channel_id) }

    it { expect(user.all_channels_with_credentials(credential_code)).to exist(id: group_member_channel2.channel_id) }

    it { expect(user.all_channels_with_credentials(credential_code)).to exist(id: channel3.id) }
  end
end
