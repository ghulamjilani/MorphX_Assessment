# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::ChannelAbility do
  let(:ability) { described_class.new(current_user) }
  let(:channel) { create(:listed_channel) }
  let(:role) { create(:access_management_group) }
  let(:enterprise) { false }
  let(:service_subscriptions) { false }
  let(:global_credentials) do
    global_credentials = JSON.parse(Rails.application.credentials.global.to_json).deep_symbolize_keys
    global_credentials[:enterprise] = enterprise
    global_credentials[:service_subscriptions][:enabled] = service_subscriptions
    global_credentials
  end

  before do
    allow(Rails.application.credentials).to receive(:global).and_return(global_credentials)
  end

  describe '#read' do
    context 'when channel is archived' do
      let(:channel) { instance_double(Channel, archived_at: Time.now, organizer: build(:user)) }

      context 'when given channel organization owner' do
        let(:current_user) { channel.organizer }

        it { expect(ability).not_to be_able_to :read, channel }
      end
    end

    context 'when channel is not approved and fake' do
      let(:channel) { create(:channel, fake: true) }

      context 'when given channel organization owner' do
        let(:current_user) { channel.organizer }

        it { expect(ability).to be_able_to :read, channel }
      end

      context 'when given invited presenter' do
        let(:presentership) { create(:channel_invited_presentership, channel: channel) }
        let(:current_user) { presentership.presenter.user }

        it { expect(ability).not_to be_able_to :read, channel }
      end
    end

    context 'when channel is approved and fake' do
      let(:channel) { create(:approved_channel, fake: true) }

      context 'when given invited presenter' do
        let(:presentership) { create(:channel_invited_presentership, channel: channel) }
        let(:current_user) { presentership.presenter.user }

        it { expect(ability).to be_able_to :read, channel }
      end

      context 'when given random user' do
        let(:current_user) { build(:user) }

        it { expect(ability).not_to be_able_to :read, channel }
      end

      context 'when enterprise' do
        let(:current_user) { create(:user) }
        let(:enterprise) { true }

        it { expect(ability).not_to be_able_to :read, channel }

        context 'when given channel member' do
          before do
            allow(current_user).to receive(:has_channel_credential?).with(channel, :view_content).and_return(true)
          end

          it { expect(ability).to be_able_to :read, channel }
        end
      end
    end
  end

  describe '#share' do
    context 'when given approved channel' do
      let(:channel) { create(:approved_channel) }
      let(:current_user) { nil }

      it { expect(ability).to be_able_to :share, channel }
    end

    context 'when given non-approved channel' do
      let(:channel) { Channel.new }
      let(:current_user) { nil }

      it { expect(ability).not_to be_able_to :share, channel }
    end
  end

  describe '#edit' do
    context 'when archived' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization, archived_at: Time.zone.now) }

      it { expect(ability).not_to be_able_to :edit, channel }
    end

    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }

      it { expect(ability).to be_able_to :edit, channel }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :edit_channel), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :edit, channel }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }

      it { expect(ability).not_to be_able_to :edit, channel }
    end
  end

  describe '#submit_for_review' do
    context 'when approved' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:channel, organization: organization, status: :approved) }

      it { expect(ability).not_to be_able_to :submit_for_review, channel }
    end

    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:channel, organization: organization) }

      it { expect(ability).to be_able_to :submit_for_review, channel }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:channel) { create(:channel, organization: organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :edit_channel), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :submit_for_review, channel }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:channel) { create(:channel, organization: organization) }

      it { expect(ability).not_to be_able_to :submit_for_review, channel }
    end
  end

  describe '#list' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }

      it { expect(ability).to be_able_to :list, channel }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :edit_channel), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { expect(ability).to be_able_to :list, channel }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }

      it { expect(ability).not_to be_able_to :list, channel }
    end
  end

  describe '#archive' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }

      it { expect(ability).to be_able_to :archive, channel }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }

      context 'when all channels' do
        before do
          member = create(:organization_membership, organization: organization, user: current_user)
          create(:access_management_groups_credential,
                 credential: create(:access_management_credential, code: :archive_channel), group: role)
          create(:access_management_groups_member, organization_membership: member, group: role)
        end

        it { expect(ability).to be_able_to :archive, channel }
      end
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }

      it { expect(ability).not_to be_able_to :archive, channel }
    end
  end

  describe '#be_notified_about_1st_published_session' do
    context 'when given channel first upcoming session' do
      let(:current_user) { create(:user) }
      let(:channel) { create(:published_session).channel.reload }

      it { expect(ability).not_to be_able_to :be_notified_about_1st_published_session, channel }
    end

    context 'when given new listed channel without any scheduled sessions' do
      let(:current_user) { create(:user) }
      let(:channel) { create(:listed_channel) }

      it { expect(ability).to be_able_to :be_notified_about_1st_published_session, channel }
    end
  end

  describe '#email_share' do
    context 'when user not logged in' do
      let(:current_user) { nil }

      it { expect(ability).not_to be_able_to :email_share, channel }
    end

    context 'when user logged in' do
      let(:current_user) { create(:user) }

      it { expect(ability).to be_able_to :email_share, channel }
    end
  end

  describe '#have_trial' do
    context 'when user not logged in' do
      let(:current_user) { nil }

      it { expect(ability).not_to be_able_to :have_trial, channel }
    end

    context 'when user logged in' do
      let(:current_user) { create(:user) }
      let(:stripe_subscription) { create(:stripe_db_subscription, status: :active) }
      let(:stripe_plan) { stripe_subscription.stripe_plan }

      context 'when channel has no plans' do
        let(:channel) { build(:approved_channel) }

        it { expect(ability).not_to be_able_to :have_trial, channel }
      end

      context 'when channel subscription and stripe subscription exist' do
        let(:channel) { stripe_plan.channel_subscription.channel }
        let(:current_user) { stripe_subscription.user }

        it { expect(ability).not_to be_able_to :have_trial, channel }
      end

      context 'when subscription exists and stripe subscription not' do
        let(:channel) { stripe_plan.channel_subscription.channel }

        it { expect(ability).to be_able_to :have_trial, channel }
      end
    end
  end

  describe '#accept_or_reject_invitation' do
    context 'when user not logged in' do
      let(:current_user) { nil }

      it { expect(ability).not_to be_able_to :accept_or_reject_invitation, channel }
    end

    context 'when given channel organizer' do
      let(:current_user) { channel.organizer }

      it { expect(ability).not_to be_able_to :accept_or_reject_invitation, channel }
    end

    context 'when given user with no invitation' do
      let(:current_user) { create(:user) }

      it { expect(ability).not_to be_able_to :accept_or_reject_invitation, channel }
    end

    context 'when given user with invitation' do
      let(:channel_invited_presentership) { create(:channel_invited_presentership_pending) }
      let(:current_user) { channel_invited_presentership.presenter.user }
      let(:channel) { channel_invited_presentership.channel }

      it { expect(ability).to be_able_to :accept_or_reject_invitation, channel }
    end
  end

  describe '#create_post' do
    context 'when user not logged in' do
      let(:current_user) { nil }

      it { expect(ability).not_to be_able_to :create_post, channel }
    end

    context 'when channel archived' do
      let(:channel) { create(:channel, archived_at: Time.now) }
      let(:current_user) { channel.organizer }

      it { expect(ability).not_to be_able_to :create_post, channel }
    end

    context 'when channel not approved' do
      let(:channel) { create(:pending_channel) }
      let(:current_user) { channel.organizer }

      it { expect(ability).not_to be_able_to :create_post, channel }
    end

    context 'when given channel organizer and channel is approved' do
      let(:channel) { create(:approved_channel) }
      let(:current_user) { channel.organizer }

      it { expect(ability).to be_able_to :create_post, channel }
    end

    context 'when given organization member with credential and channel is approved' do
      let(:channel) { create(:approved_channel) }
      let(:current_user) { create(:user) }

      before do
        allow(current_user).to receive(:has_channel_credential?).with(channel,
                                                                      :manage_blog_post).and_return(true)
      end

      it { expect(ability).to be_able_to :create_post, channel }
    end
  end

  describe '#unlist' do
    context 'when channel is not persisted' do
      let(:channel) { build(:channel) }
      let(:current_user) { create(:user) }

      it { expect { ability.can?(:unlist, channel) }.to raise_error(ArgumentError) }
    end

    context 'when given any user, even channel organizer' do
      let(:channel) { create(:listed_channel) }
      let(:current_user) { channel.organizer }

      it { expect(ability).to be_able_to :unlist, channel }
    end

    context 'when channel unlisted' do
      let(:channel) { create(:channel) }
      let(:current_user) { channel.organizer }

      it { expect(ability).not_to be_able_to :unlist, channel }
    end
  end

  describe '#create_session' do
  end

  describe '#upload_recording' do
  end

  describe '#edit_recording' do
  end

  describe '#transcode_recording' do
  end

  describe '#delete_recording' do
  end

  describe '#edit_replay' do
  end

  describe '#transcode_replay' do
  end

  describe '#delete_replay' do
  end

  describe '#manage_blog_post' do
  end

  describe '#request_session' do
  end

  describe '#subscribe' do
  end

  describe '#follow' do
  end

  describe '#like' do
  end

  describe '#edit_session_by_business_plan' do
  end

  describe '#clone_session_by_business_plan' do
  end

  describe '#cancel_session_by_business_plan' do
  end

  context 'when service subscriptions disabled' do
    describe '#create_session_by_business_plan' do
      let(:organization) { create(:organization) }
      let(:current_user) { organization.organizer }
      let(:channel) { create(:approved_channel, organization: organization) }

      it { expect(ability).to be_able_to :create_session_by_business_plan, channel }
    end

    describe '#upload_videos_by_business_plan' do
      let(:channel) { create(:channel, organization: create(:organization)) }
      let(:current_user) { channel.organizer }

      it { expect(ability).to be_able_to :upload_videos_by_business_plan, channel }
    end

    describe '#transcode_videos_by_business_plan' do
      let(:channel) { create(:channel, organization: create(:organization)) }
      let(:current_user) { channel.organizer }

      it { expect(ability).to be_able_to :transcode_videos_by_business_plan, channel }
    end
  end

  context 'when service subscriptions enabled' do
    let(:service_subscriptions) { true }

    describe '#create_session_by_business_plan' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization_with_subscription, user: current_user) }
      let(:subscription) { current_user.service_subscription }
      let(:channel) { create(:approved_channel, organization: organization) }

      %w[active trial grace].each do |status|
        it "#{status} subscription organization channel" do
          channel
          subscription.update(service_status: status)
          expect(ability).to be_able_to :create_session_by_business_plan, channel
        end
      end

      %w[new trial_suspended deactivated suspended].each do |status|
        it "channel #{status} subscription " do
          channel
          subscription.update(service_status: status)
          expect(ability).not_to be_able_to :create_session_by_business_plan, channel
        end
      end

      describe 'split_revenue organization' do
        before do
          channel
          organization.update(split_revenue_plan: true)
        end

        it { expect(ability).to be_able_to :create_session_by_business_plan, channel }
      end
    end

    describe '#upload_videos_by_business_plan' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization_with_subscription, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:subscription) { current_user.service_subscription }

      before do
        organization
      end

      it 'active subscription' do
        expect(ability).to be_able_to :upload_videos_by_business_plan, channel
      end

      %w[new trial_suspended deactivated suspended].each do |status|
        it "#{status} subscription" do
          subscription.update(service_status: status)
          expect(ability).not_to be_able_to :upload_videos_by_business_plan, channel
        end
      end

      it 'split_revenue organization' do
        organization.update(split_revenue_plan: true)
        expect(ability).to be_able_to :upload_videos_by_business_plan, channel
      end
    end

    describe '#transcode_videos_by_business_plan' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization_with_subscription, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:subscription) { current_user.service_subscription }

      before do
        organization
      end

      it 'active subscription' do
        expect(ability).to be_able_to :transcode_videos_by_business_plan, channel
      end

      %w[new trial_suspended deactivated suspended].each do |status|
        it "#{status} subscription" do
          subscription.update(service_status: status)
          expect(ability).not_to be_able_to :transcode_videos_by_business_plan, channel
        end
      end

      it 'split_revenue organization' do
        organization.update(split_revenue_plan: true)
        expect(ability).to be_able_to :transcode_videos_by_business_plan, channel
      end
    end
  end

  describe '#read_im_conversation' do
    context 'when given random user' do
      let(:current_user) { create(:user) }

      it { expect(ability).not_to be_able_to :read_im_conversation, channel }
    end

    context 'when given channel subcriber' do
      let(:current_user) { create(:user) }
      let(:channel) { create(:listed_channel) }
      let(:subscription) do
        create(:stripe_db_subscription,
               stripe_plan: create(:all_content_included_plan, channel_subscription: create(:subscription, channel: channel)),
               user: current_user)
      end

      before do
        subscription
      end

      it { expect(ability).to be_able_to :read_im_conversation, channel }
    end

    context 'when given user with participate_channel_conversation credential' do
      let(:credential) { create(:access_management_credential, code: :participate_channel_conversation) }
      let(:group) { create(:access_management_groups_credential, credential: credential).group }
      let(:groups_member) { create(:access_management_groups_member, group: group) }
      let(:groups_members_channel) { create(:access_management_groups_members_channel, groups_member: groups_member) }
      let(:channel) { groups_members_channel.channel }
      let(:current_user) { groups_members_channel.user }

      it { expect(ability).to be_able_to :read_im_conversation, channel }
    end
  end

  describe '#create_im_message' do
    context 'when given random user' do
      let(:current_user) { create(:user) }

      it { expect(ability).not_to be_able_to :create_im_message, channel }
    end

    context 'when given channel subcriber' do
      let(:current_user) { create(:user) }
      let(:channel) { create(:listed_channel) }
      let(:subscription) do
        create(:stripe_db_subscription,
               stripe_plan: create(:all_content_included_plan, channel_subscription: create(:subscription, channel: channel)),
               user: current_user)
      end

      before do
        subscription
      end

      it { expect(ability).to be_able_to :create_im_message, channel }
    end

    context 'when given user with participate_channel_conversation credential' do
      let(:credential) { create(:access_management_credential, code: :participate_channel_conversation) }
      let(:group) { create(:access_management_groups_credential, credential: credential).group }
      let(:groups_member) { create(:access_management_groups_member, group: group) }
      let(:groups_members_channel) { create(:access_management_groups_members_channel, groups_member: groups_member) }
      let(:channel) { groups_members_channel.channel }
      let(:current_user) { groups_members_channel.user }

      it { expect(ability).to be_able_to :create_im_message, channel }
    end
  end

  describe '#moderate_im_conversation' do
    context 'when given random user' do
      let(:current_user) { create(:user) }

      it { expect(ability).not_to be_able_to :moderate_im_conversation, channel }
    end

    context 'when given channel subcriber' do
      let(:current_user) { create(:user) }
      let(:channel) { create(:listed_channel) }
      let(:subscription) do
        create(:stripe_db_subscription,
               stripe_plan: create(:all_content_included_plan, channel_subscription: create(:subscription, channel: channel)),
               user: current_user)
      end

      before do
        subscription
      end

      it { expect(ability).not_to be_able_to :moderate_im_conversation, channel }
    end

    context 'when given user with participate_channel_conversation credential' do
      let(:credential) { create(:access_management_credential, code: :participate_channel_conversation) }
      let(:group) { create(:access_management_groups_credential, credential: credential).group }
      let(:groups_member) { create(:access_management_groups_member, group: group) }
      let(:groups_members_channel) { create(:access_management_groups_members_channel, groups_member: groups_member) }
      let(:channel) { groups_members_channel.channel }
      let(:current_user) { groups_members_channel.user }

      it { expect(ability).not_to be_able_to :moderate_im_conversation, channel }
    end

    context 'when given user with moderate_channel_conversation credential' do
      let(:credential) { create(:access_management_credential, code: :moderate_channel_conversation) }
      let(:group) { create(:access_management_groups_credential, credential: credential).group }
      let(:groups_member) { create(:access_management_groups_member, group: group) }
      let(:groups_members_channel) { create(:access_management_groups_members_channel, groups_member: groups_member) }
      let(:channel) { groups_members_channel.channel }
      let(:current_user) { groups_members_channel.user }

      it { expect(ability).to be_able_to :moderate_im_conversation, channel }
    end
  end
end
