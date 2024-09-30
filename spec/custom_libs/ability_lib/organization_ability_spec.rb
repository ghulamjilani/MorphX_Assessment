# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::OrganizationAbility do
  let(:ability) { described_class.new(current_user) }
  let(:role) { create(:access_management_group) }
  let(:global_subscription_credentials) do
    global_credentials = JSON.parse(Rails.application.credentials.global.to_json).deep_symbolize_keys
    global_credentials[:service_subscriptions][:enabled] = true
    global_credentials
  end
  let(:service_subscriptions) { false }

  before do
    if service_subscriptions
      allow(Rails.application.credentials).to receive(:global).and_return(global_subscription_credentials)
    end
  end

  describe '#access(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :access, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        create(:organization_membership, organization: organization, user: current_user)
      end

      it { expect(ability).to be_able_to :access, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :access, organization }
    end

    context 'when given service_admin user' do
      let(:current_user) { create(:user_service_admin) }
      let(:organization) { create(:organization) }

      it { expect(ability).to be_able_to :access, organization }
    end
  end

  describe '#edit(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :edit, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_organization), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :edit, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :edit, organization }
    end
  end

  describe '#create_channel(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :create_channel, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :create_channel), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :create_channel, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :create_channel, organization }
    end
  end

  describe '#edit_channels(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :edit_channels, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :edit_channel), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :edit_channels, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :edit_channels, organization }
    end
  end

  describe '#archive_channels(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :archive_channels, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :archive_channel), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :archive_channels, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :archive_channels, organization }
    end
  end

  describe '#create_session(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :create_session, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :create_session), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :create_session, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :create_session, organization }
    end
  end

  #   can :upload_recording, Organization do |organization|
  #     organization.user == user || can?(:access, organization) && lambda do
  #       user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'create_recording')
  #     end.call
  #   end

  describe '#upload_recording(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :upload_recording, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :create_recording), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :upload_recording, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :upload_recording, organization }
    end
  end

  describe '#edit_recording(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :edit_recording, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :edit_recording), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :edit_recording, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :edit_recording, organization }
    end
  end

  describe '#transcode_recording(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :transcode_recording, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :transcode_recording), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :transcode_recording, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :transcode_recording, organization }
    end
  end

  describe '#delete_recording(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :delete_recording, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :delete_recording), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :delete_recording, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :delete_recording, organization }
    end
  end

  describe '#edit_replay(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :edit_replay, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :edit_replay), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :edit_replay, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :edit_replay, organization }
    end
  end

  describe '#transcode_replay(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :transcode_replay, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :transcode_replay), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :transcode_replay, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :transcode_replay, organization }
    end
  end

  describe '#delete_replay(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :delete_replay, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :delete_replay), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :delete_replay, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :delete_replay, organization }
    end
  end

  describe '#manage_product(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :manage_product, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_product), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :manage_product, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :manage_product, organization }
    end
  end

  describe '#manage_roles(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :manage_roles, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_roles), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :manage_roles, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :manage_roles, organization }
    end
  end

  describe '#manage_admin(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :manage_admin, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_admin), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :manage_admin, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :manage_admin, organization }
    end
  end

  describe '#manage_creator(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :manage_creator, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_creator), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :manage_creator, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :manage_creator, organization }
    end
  end

  describe '#manage_enterprise_member(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :manage_enterprise_member, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_enterprise_member), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :manage_enterprise_member, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :manage_enterprise_member, organization }
    end
  end

  describe '#manage_superadmin(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :manage_superadmin, organization }
    end
  end

  describe '#manage_channel_subscription(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :manage_channel_subscription, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_channel_subscription), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :manage_channel_subscription, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :manage_channel_subscription, organization }
    end
  end

  describe '#manage_business_plan(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :manage_business_plan, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_business_plan), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :manage_business_plan, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :manage_business_plan, organization }
    end
  end

  describe '#refund(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :refund, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential, credential: create(:access_management_credential, code: :refund),
                                                     group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :refund, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :refund, organization }
    end
  end

  describe '#manage_payment_method(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :manage_payment_method, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_payment_method), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :manage_payment_method, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :manage_payment_method, organization }
    end
  end

  describe '#view_user_report(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :view_user_report, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :view_user_report), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :view_user_report, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :view_user_report, organization }
    end
  end

  describe '#view_video_report(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :view_video_report, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :view_video_report), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :view_video_report, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :view_video_report, organization }
    end
  end

  describe '#view_billing_report(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :view_billing_report, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :view_billing_report), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :view_billing_report, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :view_billing_report, organization }
    end
  end

  describe '#view_revenue_report(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :view_revenue_report, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :view_revenue_report), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :view_revenue_report, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :view_revenue_report, organization }
    end
  end

  describe '#view_content(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :view_content, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :view_content), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :view_content, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :view_content, organization }
    end
  end

  describe '#manage_blog_post(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :manage_blog_post, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_blog_post), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :manage_blog_post, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :manage_blog_post, organization }
    end
  end

  describe '#moderate_blog_post(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { expect(ability).to be_able_to :moderate_blog_post, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :moderate_blog_post), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :moderate_blog_post, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { expect(ability).not_to be_able_to :moderate_blog_post, organization }
    end
  end

  context 'when service subscriptions disabled' do
    describe '#monetize_content' do
      let(:organization) { create(:organization) }
      let(:channel) { create(:channel, organization: organization) }
      let(:current_user) { organization.organizer }

      it { expect(ability).to be_able_to :monetize_content_by_business_plan, organization }
    end

    describe '#manage_blog' do
      let(:organization) { create(:organization) }
      let(:current_user) { organization.organizer }

      it { expect(ability).to be_able_to :manage_blog_by_business_plan, organization }
    end

    describe '#manage_multiroom Organization' do
      let(:organization) { create(:organization) }
      let(:current_user) { organization.organizer }

      it { expect(ability).to be_able_to :manage_multiroom_by_business_plan, organization }
    end

    describe '#access_multiroom Organization' do
      let(:organization) { create(:organization, multiroom_status: 'enabled') }
      let(:current_user) { organization.organizer }

      it { expect(ability).to be_able_to :access_multiroom_by_business_plan, organization }

      it 'don\'t allow when multiroom disabled' do
        allow(organization).to receive(:multiroom_enabled?).and_return(false)
        expect(ability).not_to be_able_to :access_multiroom_by_business_plan, organization
      end
    end

    describe '#access_products' do
      let(:organization) { create(:organization, multiroom_status: 'enabled') }
      let(:channel) { create(:channel, organization: organization) }
      let(:current_user) { organization.organizer }

      it { expect(ability).to be_able_to :access_products_by_business_plan, organization }
    end

    describe '#create_channel Organization' do
      let(:organization) { create(:organization, multiroom_status: 'enabled') }
      let(:current_user) { organization.organizer }

      it { expect(ability).to be_able_to :create_channel_by_business_plan, organization }
    end

    describe '#create_session' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }

      it { expect(ability).to be_able_to :create_session_by_business_plan, organization }
    end

    describe '#manage_creators' do
      let(:organization) { create(:organization) }
      let(:channel) { create(:channel, organization: organization) }
      let(:current_user) { organization.organizer }

      it { expect(ability).to be_able_to :manage_creators_by_business_plan, organization }
    end

    describe '#manage_contacts_and_mailing' do
      let(:organization) { create(:organization) }
      let(:current_user) { organization.organizer }

      it { expect(ability).to be_able_to :manage_contacts_and_mailing_by_business_plan, organization }
    end
  end

  context 'when service subscriptions enabled' do
    let(:service_subscriptions) { true }

    describe '#monetize_content' do
      let(:organization) { create(:organization) }
      let(:channel) { create(:channel, organization: organization) }
      let(:current_user) { organization.user }
      let(:subscription) do
        create(:stripe_service_subscription, user: current_user, status: 'active', service_status: 'active')
      end

      before do
        subscription
      end

      it 'active subscription for organization' do
        expect(ability).to be_able_to :monetize_content_by_business_plan, organization
      end

      %w[new trial_suspended deactivated suspended].each do |status|
        describe "#{status} subscription" do
          let(:subscription) { create(:stripe_service_subscription, user: current_user, service_status: status) }

          before do
            subscription
          end

          it { expect(ability).not_to be_able_to :monetize_content_by_business_plan, organization }
        end
      end

      describe 'split_revenue organization' do
        before do
          organization.update(split_revenue_plan: true)
        end

        it { expect(ability).to be_able_to :monetize_content_by_business_plan, organization }
      end
    end

    describe '#manage_blog' do
      let(:organization) { create(:organization_with_subscription) }
      let(:current_user) { organization.user }
      let(:subscription) { current_user.service_subscription }

      describe 'enabled community_blog' do
        before do
          create(:feature_parameter, plan_package: subscription.plan_package,
                                     plan_feature: create(:community_blog_plan_feature), value: true)
        end

        it { expect(ability).to be_able_to :manage_blog_by_business_plan, organization }
      end

      describe 'disabled community_blog' do
        before do
          create(:feature_parameter, plan_package: subscription.plan_package,
                                     plan_feature: create(:community_blog_plan_feature), value: false)
        end

        it { expect(ability).not_to be_able_to :manage_blog_by_business_plan, organization }
      end

      describe 'split_revenue organization' do
        before do
          organization.update(split_revenue_plan: true)
        end

        it { expect(ability).to be_able_to :manage_blog_by_business_plan, organization }
      end
    end

    describe '#manage_multiroom' do
      let(:organization) { create(:organization_with_subscription) }
      let(:current_user) { organization.user }
      let(:subscription) { current_user.service_subscription }

      describe 'enabled multi_room' do
        before do
          create(:feature_parameter, plan_package: subscription.plan_package,
                                     plan_feature: create(:multi_room_plan_feature), value: true)
        end

        it { expect(ability).to be_able_to :manage_multiroom_by_business_plan, organization }
      end

      describe 'disabled multi_room' do
        before do
          create(:feature_parameter, plan_package: subscription.plan_package,
                                     plan_feature: create(:multi_room_plan_feature), value: false)
        end

        it { expect(ability).not_to be_able_to :manage_multiroom_by_business_plan, organization }
      end

      describe 'split_revenue organization' do
        before do
          organization.update(split_revenue_plan: true)
        end

        it { expect(ability).to be_able_to :manage_multiroom_by_business_plan, organization }
      end
    end

    describe '#access_multiroom' do
      let(:organization) { create(:organization_with_subscription, multiroom_status: 'enabled') }
      let(:current_user) { organization.organizer }
      let(:subscription) { current_user.service_subscription }

      describe 'enabled multi_room' do
        before do
          create(:feature_parameter, plan_package: subscription.plan_package,
                                     plan_feature: create(:multi_room_plan_feature), value: true)
        end

        it { expect(ability).to be_able_to :access_multiroom_by_business_plan, organization }
      end

      describe 'disabled multi_room' do
        before do
          create(:feature_parameter, plan_package: subscription.plan_package,
                                     plan_feature: create(:multi_room_plan_feature), value: false)
        end

        it { expect(ability).not_to be_able_to :access_multiroom_by_business_plan, organization }
      end

      describe 'split_revenue organization' do
        before do
          organization.update(split_revenue_plan: true)
        end

        it { expect(ability).to be_able_to :access_multiroom_by_business_plan, organization }
      end

      it 'don\'t allow when multiroom disabled' do
        allow(Organization).to receive(:multiroom_enabled?).and_return(false)
        expect(ability).not_to be_able_to :access_multiroom_by_business_plan, organization
      end
    end

    describe '#access_products' do
      let(:organization) { create(:organization_with_subscription, multiroom_status: 'enabled') }
      let(:channel) { create(:channel, organization: organization) }
      let(:current_user) { organization.organizer }
      let(:subscription) { current_user.service_subscription }

      before do
        channel
      end

      describe 'enabled instream_shopping' do
        before do
          create(:feature_parameter, plan_package: subscription.plan_package,
                                     plan_feature: create(:instream_shopping_plan_feature), value: true)
        end

        it { expect(ability).to be_able_to :access_products_by_business_plan, organization }
      end

      describe 'disabled instream_shopping' do
        before do
          create(:feature_parameter, plan_package: subscription.plan_package,
                                     plan_feature: create(:instream_shopping_plan_feature), value: false)
        end

        it { expect(ability).not_to be_able_to :access_products_by_business_plan, organization }
      end

      describe 'split_revenue organization' do
        before do
          organization.update(split_revenue_plan: true)
        end

        it { expect(ability).to be_able_to :access_products_by_business_plan, organization }
      end
    end

    describe '#create_channel' do
      let(:organization) { create(:organization_with_subscription, multiroom_status: 'enabled') }
      let(:current_user) { organization.organizer }
      let(:subscription) { current_user.service_subscription }
      let(:channel) { create(:channel, organization: organization) }

      it 'allowed max_channels_count' do
        channel
        create(:feature_parameter, plan_package: subscription.plan_package,
                                   plan_feature: create(:max_channels_count_plan_feature), value: 2)
        expect(ability).to be_able_to :create_channel_by_business_plan, organization
      end

      it 'reached max_channels_count' do
        channel
        create(:feature_parameter, plan_package: subscription.plan_package,
                                   plan_feature: create(:max_channels_count_plan_feature), value: 1)
        expect(ability).not_to be_able_to :create_channel_by_business_plan, organization
      end

      it 'split_revenue organization organization' do
        channel
        organization.update(split_revenue_plan: true)
        expect(ability).to be_able_to :create_channel_by_business_plan, organization
      end
    end

    describe '#create_session' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization_with_subscription, user: current_user) }
      let(:subscription) { current_user.service_subscription }
      let(:channel) { create(:approved_channel, organization: organization) }

      %w[active trial grace].each do |status|
        it "#{status} subscription organization" do
          channel
          subscription.update(service_status: status)
          expect(ability).to be_able_to :create_session_by_business_plan, organization
        end
      end

      %w[new trial_suspended deactivated suspended].each do |status|
        it "organization #{status} subscription " do
          channel
          subscription.update(service_status: status)
          expect(ability).not_to be_able_to :create_session_by_business_plan, organization
        end
      end

      describe 'split_revenue organization' do
        before do
          channel
          organization.update(split_revenue_plan: true)
        end

        it { expect(ability).to be_able_to :create_session_by_business_plan, organization }
      end
    end

    describe '#manage_creators' do
      let(:organization) { create(:organization_with_subscription, multiroom_status: 'enabled') }
      let(:current_user) { organization.organizer }
      let(:subscription) { current_user.service_subscription }
      let(:channel) { create(:channel, organization: organization) }

      before do
        channel
      end

      it 'enabled manage_creators organization' do
        create(:feature_parameter, plan_package: subscription.plan_package,
                                   plan_feature: create(:manage_creators_plan_feature), value: true)
        expect(ability).to be_able_to :manage_creators_by_business_plan, organization
      end

      it 'disabled manage_creators' do
        create(:feature_parameter, plan_package: subscription.plan_package,
                                   plan_feature: create(:manage_creators_plan_feature), value: false)
        expect(ability).not_to be_able_to :create_channel_by_business_plan, organization
      end

      it 'split_revenue organization organization' do
        organization.update(split_revenue_plan: true)
        expect(ability).to be_able_to :manage_creators_by_business_plan, organization
      end
    end

    describe '#manage_contacts_and_mailing' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization_with_subscription, user: current_user) }
      let(:subscription) { current_user.service_subscription }

      before do
        organization
      end

      # 'active subscription'
      it { expect(ability).to be_able_to :manage_contacts_and_mailing_by_business_plan, organization }

      %w[new deactivated suspended].each do |status|
        it "#{status} subscription for organization" do
          subscription.update(service_status: status)
          expect(ability).not_to be_able_to :manage_contacts_and_mailing_by_business_plan, organization
        end
      end

      it 'split_revenue organization for organization' do
        organization.update!(split_revenue_plan: true)
        expect(ability).to be_able_to :manage_contacts_and_mailing_by_business_plan, organization
      end
    end

    describe '#manage_team' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization_with_subscription, user: current_user) }
      let(:subscription) { current_user.service_subscription }

      before do
        organization
        create(:feature_parameter, plan_package: subscription.plan_package,
                                   plan_feature: create(:manage_creators_plan_feature, parameter_type: 'boolean'),
                                   value: 'true')
      end

      %w[active pending_deactivation trial trial_suspended grace].each do |status|
        it "#{status} subscription for organization works" do
          subscription.update(service_status: status)
          expect(ability).to be_able_to :manage_team, organization
        end
      end

      %w[new deactivated suspended].each do |status|
        it "#{status} subscription for organization does not work" do
          subscription.update(service_status: status)
          expect(ability).not_to be_able_to :manage_team, organization
        end
      end

      it 'split_revenue organization for organization' do
        organization.update!(split_revenue_plan: true)
        expect(ability).to be_able_to :manage_team, organization
      end
    end
  end
end
