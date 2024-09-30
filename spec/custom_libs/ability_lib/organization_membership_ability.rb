# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::OrganizationMembershipAbility do
  let(:ability) { described_class.new(current_user) }
  let(:role) { create(:access_management_group) }

  describe '#read(OrganizationMembership)' do
    context 'when status active' do
      let(:organization_membership) { create(:organization_membership_active) }
      let(:current_user) { create(:user) }

      it { expect(ability).to be_able_to :read, organization_membership }
    end

    context 'when status pending' do
      let(:organization_membership) { create(:organization_membership_pending) }

      context 'when given random user' do
        let(:current_user) { create(:user) }

        it { expect(ability).not_to be_able_to :read, organization_membership }
      end

      context 'when given invited user' do
        let(:current_user) { organization_membership.user }

        it { expect(ability).to be_able_to :read, organization_membership }
      end

      context 'when given organization owner' do
        let(:current_user) { organization_membership.organization.user }

        it { expect(ability).to be_able_to :read, organization_membership }
      end

      context 'when given organization member with necessary credentials' do
        let(:groups_credential) do
          create(:access_management_groups_credential, credential: create(:access_management_credential, code: :manage_admin),
                                                       group: role)
        end
        let(:access_management_groups_member) do
          create(:access_management_groups_member, group: groups_credential.group)
        end
        let(:membership_with_access) { access_management_groups_member.organization_membership }
        let(:organization) { membership_with_access.organization }
        let(:organization_membership) { create(:organization_membership_pending, organization: organization) }
        let(:current_user) { membership_with_access.user }

        it { expect(ability).to be_able_to :read, organization_membership }
      end
    end
  end

  describe '#edit_roles' do
    context 'when organization owner' do
      let(:current_user) { organization_membership.organization.user }
      let(:organization_membership) { create(:organization_membership) }

      it { expect(ability).to be_able_to :edit_roles, organization_membership }
    end

    context 'when organization_membership user' do
      let(:current_user) { organization_membership.user }
      let(:organization_membership) { create(:organization_membership) }

      it { expect(ability).not_to be_able_to :edit_roles, organization_membership }
    end

    context 'when organization member with credentials' do
      let(:current_user) { create(:user) }
      let(:organization_membership) { create(:organization_membership) }

      before do
        allow(current_user).to receive(:has_organization_credential?).with(organization_membership.organization,
                                                                           :manage_roles).and_return(true)
      end

      context 'when editing other user\'s role' do
        it { expect(ability).to be_able_to :edit_roles, organization_membership }
      end

      context 'when editing own role' do
        let(:current_user) { organization_membership.user }

        it { expect(ability).not_to be_able_to :edit_roles, organization_membership }
      end
    end
  end
end
