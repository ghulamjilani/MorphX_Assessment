# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::AccessManagement::GroupAbility do
  let(:subject) { described_class.new(current_user) }
  let(:role) { create(:access_management_group) }

  describe '#add_credential(AccessManagement::Group, AccessManagement::Credential)' do
    let(:current_user) { create(:user) }
    let(:organization) { create(:organization, user: current_user) }
    let(:organization_membership) { build(:organization_membership, organization: organization) }
    let(:role2) { create(:access_management_organizational_group, organization: organization) }
    let(:admin_credential) { create(:admin_credential) }
    let(:creator_credential) { create(:creator_credential) }

    before do
      create(:access_management_groups_member, organization_membership: organization_membership, group: role2)
      current_user.update(current_organization_id: organization.id)
    end

    context 'when no subscriptions' do
      it { is_expected.to be_able_to :add_credential, role2, admin_credential }
      it { is_expected.to be_able_to :add_credential, role2, creator_credential }
    end

    context 'when subscriptions enabled' do
      let!(:subscription) { create(:stripe_service_subscription, user: current_user, organization: organization) }
      let(:admin_plan_feature) { create(:plan_feature, code: :max_admins_count) }
      let(:creator_plan_feature) { create(:plan_feature, code: :max_creators_count) }

      before do
        Rails.application.credentials.global[:service_subscriptions][:enabled] = true
      end

      after do
        Rails.application.credentials.global[:service_subscriptions][:enabled] = false
      end

      context 'when adding admin' do
        before do
          create(:feature_parameter, value: 0, plan_feature: admin_plan_feature, plan_package: subscription.stripe_plan.plan_package)
          create(:feature_parameter, value: 1, plan_feature: creator_plan_feature, plan_package: subscription.stripe_plan.plan_package)
        end

        it { is_expected.to be_able_to :add_credential, role2, creator_credential }
        it { is_expected.not_to be_able_to :add_credential, role2, admin_credential }
      end

      context 'when adding creator' do
        before do
          create(:feature_parameter, value: 1, plan_feature: admin_plan_feature, plan_package: subscription.stripe_plan.plan_package)
          create(:feature_parameter, value: 0, plan_feature: creator_plan_feature, plan_package: subscription.stripe_plan.plan_package)
        end

        it { is_expected.to be_able_to :add_credential, role2, admin_credential }
        it { is_expected.not_to be_able_to :add_credential, role2, creator_credential }
      end
    end
  end

  describe '#add_role(AccessManagement::Group, OrganizationMembership)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }
      let(:organization_membership) { build(:organization_membership, organization: organization) }
      let(:role1) { create(:access_management_group) }

      before do
        current_user.update(current_organization_id: organization.id)
      end

      it { is_expected.to be_able_to :add_role, role1, organization_membership }
    end

    context 'when add admin and member is admin' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:member) { create(:organization_membership, organization: organization, user: current_user) }
      let(:organization_membership) { build(:organization_membership, organization: organization) }
      let(:role1) { create(:access_management_group) }

      before do
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_admin, type: create(:access_management_type, name: 'Admin')), group: role1)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_admin), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
        current_user.update(current_organization_id: organization.id)
      end

      it { is_expected.to be_able_to :add_role, role1, organization_membership }
    end

    context 'when add admin and member is not admin' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:member) { create(:organization_membership, organization: organization, user: current_user) }
      let(:organization_membership) { build(:organization_membership, organization: organization) }
      let(:role1) { create(:access_management_group) }

      before do
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_admin, type: create(:access_management_type, name: 'Admin')), group: role1)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_creator), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
        current_user.update(current_organization_id: organization.id)
      end

      it { is_expected.not_to be_able_to :add_role, role1, organization_membership }
    end

    context 'when add creator and member is creator' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:member) { create(:organization_membership, organization: organization, user: current_user) }
      let(:organization_membership) { build(:organization_membership, organization: organization) }
      let(:role1) { create(:access_management_group) }

      before do
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, type: create(:access_management_type, name: 'Creator')), group: role1)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_creator), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
        current_user.update(current_organization_id: organization.id)
      end

      it { is_expected.to be_able_to :add_role, role1, organization_membership }
    end

    context 'when add member and user is admin' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:member) { create(:organization_membership, organization: organization, user: current_user) }
      let(:organization_membership) { build(:organization_membership, organization: organization) }
      let(:role1) { create(:access_management_group) }

      before do
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, type: create(:access_management_type, name: 'Member')), group: role1)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_enterprise_member), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
        current_user.update(current_organization_id: organization.id)
      end

      it { is_expected.to be_able_to :add_role, role1, organization_membership }
    end
  end
end
