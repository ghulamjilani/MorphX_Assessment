# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::Legacy::ServiceSubscriptionAbility do
  context 'when service subscriptions disabled' do
    let(:service) { described_class.new(current_user) }

    before do
      Rails.application.credentials.global[:service_subscriptions][:enabled] = false
    end

    describe '#access_wizard' do
      let(:current_user) { create(:user) }

      it { expect(service).to be_able_to :access_wizard_by_business_plan, current_user }
    end

    describe '#edit StripeDb::ServiceSubscription' do
      let(:current_user) { create(:user) }

      it { expect(service).not_to be_able_to :edit_by_business_plan, instance_double('service_subscriptions') }
    end

    describe '#monetize_content' do
      let(:organization) { create(:organization) }
      let(:channel) { create(:channel, organization: organization) }
      let(:current_user) { organization.organizer }

      it { expect(service).to be_able_to :monetize_content_by_business_plan, organization }
      it { expect(service).to be_able_to :monetize_content_by_business_plan, channel }
    end

    describe '#manage_blog' do
      let(:organization) { create(:organization) }
      let(:current_user) { organization.organizer }

      it { expect(service).to be_able_to :manage_blog_by_business_plan, organization }
      it { expect(service).to be_able_to :manage_blog_by_business_plan, current_user }
    end

    describe '#manage_multiroom Organization' do
      let(:organization) { create(:organization) }
      let(:current_user) { organization.organizer }

      it { expect(service).to be_able_to :manage_multiroom_by_business_plan, organization }
    end

    describe '#access_multiroom Organization' do
      let(:organization) { create(:organization, multiroom_status: 'enabled') }
      let(:current_user) { organization.organizer }

      it { expect(service).to be_able_to :access_multiroom_by_business_plan, organization }

      it 'don\'t allow when multiroom disabled' do
        allow(organization).to receive(:multiroom_enabled?).and_return(false)
        expect(service).not_to be_able_to :access_multiroom_by_business_plan, organization
      end
    end

    describe '#access_products' do
      let(:organization) { create(:organization, multiroom_status: 'enabled') }
      let(:channel) { create(:channel, organization: organization) }
      let(:current_user) { organization.organizer }

      it { expect(service).to be_able_to :access_products_by_business_plan, organization }
      it { expect(service).to be_able_to :access_products_by_business_plan, channel }
      it { expect(service).to be_able_to :access_products_by_business_plan, current_user }
    end

    describe '#create_channel Organization' do
      let(:organization) { create(:organization, multiroom_status: 'enabled') }
      let(:current_user) { organization.organizer }

      it { expect(service).to be_able_to :create_channel_by_business_plan, organization }
    end

    describe '#create_session_by_business_plan' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }

      it { expect(service).to be_able_to :create_session_by_business_plan, organization }
      it { expect(service).to be_able_to :create_session_by_business_plan, channel }

      it 'user present' do
        organization # setup current organization
        expect(service).to be_able_to :create_session_by_business_plan, current_user
      end
    end

    describe '#upload_videos_by_business_plan' do
      let(:channel) { create(:channel, organization: create(:organization)) }
      let(:current_user) { channel.organizer }

      it { expect(service).to be_able_to :upload_videos_by_business_plan, channel }
    end

    describe '#transcode_videos_by_business_plan' do
      let(:channel) { create(:channel, organization: create(:organization)) }
      let(:current_user) { channel.organizer }

      it { expect(service).to be_able_to :transcode_videos_by_business_plan, channel }
    end

    describe '#manage_creators' do
      let(:organization) { create(:organization) }
      let(:channel) { create(:channel, organization: organization) }
      let(:current_user) { organization.organizer }

      it { expect(service).to be_able_to :manage_creators_by_business_plan, organization }
      it { expect(service).to be_able_to :manage_creators_by_business_plan, channel }
    end

    describe '#manage_contacts_and_mailing' do
      let(:organization) { create(:organization) }
      let(:current_user) { organization.organizer }

      it { expect(service).to be_able_to :manage_contacts_and_mailing_by_business_plan, organization }
      it { expect(service).to be_able_to :manage_contacts_and_mailing_by_business_plan, current_user }
    end
  end

  context 'when service subscriptions enabled' do
    let(:service) { described_class.new(current_user) }

    before do
      Rails.application.credentials.global[:service_subscriptions][:enabled] = true
    end

    after do
      Rails.application.credentials.global[:service_subscriptions][:enabled] = false
    end

    describe '#access_wizard' do
      let(:current_user) { create(:user) }
      let(:subscription) { create(:stripe_service_subscription, user: current_user) }

      it 'without subscription' do
        expect(service).not_to be_able_to :access_wizard_by_business_plan, current_user
      end

      describe 'with subscription' do
        it 'with subscription' do
          subscription
          expect(service).to be_able_to :access_wizard_by_business_plan, current_user
        end
      end
    end

    describe '#edit StripeDb::ServiceSubscription' do
      let(:current_user) { create(:user) }
      let(:subscription) { create(:stripe_service_subscription, user: current_user) }

      it { expect(service).to be_able_to :edit_by_business_plan, subscription }
      it { expect(service).not_to be_able_to :edit_by_business_plan, instance_double('stripe_service_subscription') }
    end

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
        expect(service).to be_able_to :monetize_content_by_business_plan, organization
      end

      it 'active subscription for channel' do
        expect(service).to be_able_to :monetize_content_by_business_plan, channel
      end

      %w[new trial_suspended deactivated suspended].each do |status|
        describe "#{status} subscription" do
          let(:subscription) { create(:stripe_service_subscription, user: current_user, service_status: status) }

          before do
            subscription
          end

          it { expect(service).not_to be_able_to :monetize_content_by_business_plan, organization }
          it { expect(service).not_to be_able_to :monetize_content_by_business_plan, channel }
        end
      end

      describe 'split_revenue organization' do
        before do
          organization.update(split_revenue_plan: true)
        end

        it { expect(service).to be_able_to :monetize_content_by_business_plan, organization }
        it { expect(service).to be_able_to :monetize_content_by_business_plan, channel }
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

        it { expect(service).to be_able_to :manage_blog_by_business_plan, organization }
        it { expect(service).to be_able_to :manage_blog_by_business_plan, current_user }
      end

      describe 'disabled community_blog' do
        before do
          create(:feature_parameter, plan_package: subscription.plan_package,
                                     plan_feature: create(:community_blog_plan_feature), value: false)
        end

        it { expect(service).not_to be_able_to :manage_blog_by_business_plan, organization }
        it { expect(service).not_to be_able_to :manage_blog_by_business_plan, current_user }
      end

      describe 'split_revenue organization' do
        before do
          organization.update(split_revenue_plan: true)
        end

        it { expect(service).to be_able_to :manage_blog_by_business_plan, organization }
        it { expect(service).to be_able_to :manage_blog_by_business_plan, current_user }
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

        it { expect(service).to be_able_to :manage_multiroom_by_business_plan, organization }
      end

      describe 'disabled multi_room' do
        before do
          create(:feature_parameter, plan_package: subscription.plan_package,
                                     plan_feature: create(:multi_room_plan_feature), value: false)
        end

        it { expect(service).not_to be_able_to :manage_multiroom_by_business_plan, organization }
      end

      describe 'split_revenue organization' do
        before do
          organization.update(split_revenue_plan: true)
        end

        it { expect(service).to be_able_to :manage_multiroom_by_business_plan, organization }
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

        it { expect(service).to be_able_to :access_multiroom_by_business_plan, organization }
      end

      describe 'disabled multi_room' do
        before do
          create(:feature_parameter, plan_package: subscription.plan_package,
                                     plan_feature: create(:multi_room_plan_feature), value: false)
        end

        it { expect(service).not_to be_able_to :access_multiroom_by_business_plan, organization }
      end

      describe 'split_revenue organization' do
        before do
          organization.update(split_revenue_plan: true)
        end

        it { expect(service).to be_able_to :access_multiroom_by_business_plan, organization }
      end

      it 'don\'t allow when multiroom disabled' do
        allow(Organization).to receive(:multiroom_enabled?).and_return(false)
        expect(service).not_to be_able_to :access_multiroom_by_business_plan, organization
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

        it { expect(service).to be_able_to :access_products_by_business_plan, organization }
        it { expect(service).to be_able_to :access_products_by_business_plan, channel }
        it { expect(service).to be_able_to :access_products_by_business_plan, current_user }
      end

      describe 'disabled instream_shopping' do
        before do
          create(:feature_parameter, plan_package: subscription.plan_package,
                                     plan_feature: create(:instream_shopping_plan_feature), value: false)
        end

        it { expect(service).not_to be_able_to :access_products_by_business_plan, organization }
        it { expect(service).not_to be_able_to :access_products_by_business_plan, channel }
        it { expect(service).not_to be_able_to :access_products_by_business_plan, current_user }
      end

      describe 'split_revenue organization' do
        before do
          organization.update(split_revenue_plan: true)
        end

        it { expect(service).to be_able_to :access_products_by_business_plan, organization }
        it { expect(service).to be_able_to :access_products_by_business_plan, channel }
        it { expect(service).to be_able_to :access_products_by_business_plan, current_user }
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
        expect(service).to be_able_to :create_channel_by_business_plan, organization
      end

      it 'reached max_channels_count' do
        channel
        create(:feature_parameter, plan_package: subscription.plan_package,
                                   plan_feature: create(:max_channels_count_plan_feature), value: 1)
        expect(service).not_to be_able_to :create_channel_by_business_plan, organization
      end

      it 'split_revenue organization organization' do
        channel
        organization.update(split_revenue_plan: true)
        expect(service).to be_able_to :create_channel_by_business_plan, organization
      end
    end

    describe '#create_session_by_business_plan' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization_with_subscription, user: current_user) }
      let(:subscription) { current_user.service_subscription }
      let(:channel) { create(:approved_channel, organization: organization) }

      %w[active trial grace].each do |status|
        it "#{status} subscription organization" do
          channel
          subscription.update(service_status: status)
          expect(service).to be_able_to :create_session_by_business_plan, organization
        end

        it "#{status} subscription organization channel" do
          channel
          subscription.update(service_status: status)
          expect(service).to be_able_to :create_session_by_business_plan, channel
        end

        it "#{status} subscription organization current_user" do
          channel
          subscription.update(service_status: status)
          expect(service).to be_able_to :create_session_by_business_plan, current_user
        end
      end

      %w[new trial_suspended deactivated suspended].each do |status|
        it "organization #{status} subscription " do
          channel
          subscription.update(service_status: status)
          expect(service).not_to be_able_to :create_session_by_business_plan, organization
        end

        it "channel #{status} subscription " do
          channel
          subscription.update(service_status: status)
          expect(service).not_to be_able_to :create_session_by_business_plan, channel
        end

        it "current_user #{status} subscription " do
          channel
          subscription.update(service_status: status)
          expect(service).not_to be_able_to :create_session_by_business_plan, current_user
        end
      end

      describe 'split_revenue organization' do
        before do
          channel
          organization.update(split_revenue_plan: true)
        end

        it { expect(service).to be_able_to :create_session_by_business_plan, organization }
        it { expect(service).to be_able_to :create_session_by_business_plan, channel }
        it { expect(service).to be_able_to :create_session_by_business_plan, current_user }
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
        expect(service).to be_able_to :upload_videos_by_business_plan, channel
      end

      %w[new trial_suspended deactivated suspended].each do |status|
        it "#{status} subscription" do
          subscription.update(service_status: status)
          expect(service).not_to be_able_to :upload_videos_by_business_plan, channel
        end
      end

      it 'split_revenue organization' do
        organization.update(split_revenue_plan: true)
        expect(service).to be_able_to :upload_videos_by_business_plan, channel
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
        expect(service).to be_able_to :transcode_videos_by_business_plan, channel
      end

      %w[new trial_suspended deactivated suspended].each do |status|
        it "#{status} subscription" do
          subscription.update(service_status: status)
          expect(service).not_to be_able_to :transcode_videos_by_business_plan, channel
        end
      end

      it 'split_revenue organization' do
        organization.update(split_revenue_plan: true)
        expect(service).to be_able_to :transcode_videos_by_business_plan, channel
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
        expect(service).to be_able_to :manage_creators_by_business_plan, organization
      end

      it 'enabled manage_creators channel' do
        create(:feature_parameter, plan_package: subscription.plan_package,
                                   plan_feature: create(:manage_creators_plan_feature), value: true)
        expect(service).to be_able_to :manage_creators_by_business_plan, channel
      end

      it 'disabled manage_creators' do
        create(:feature_parameter, plan_package: subscription.plan_package,
                                   plan_feature: create(:manage_creators_plan_feature), value: false)
        expect(service).not_to be_able_to :create_channel_by_business_plan, organization
      end

      it 'split_revenue organization organization' do
        organization.update(split_revenue_plan: true)
        expect(service).to be_able_to :manage_creators_by_business_plan, organization
      end

      it 'split_revenue organization organization channel' do
        organization.update(split_revenue_plan: true)
        expect(service).to be_able_to :manage_creators_by_business_plan, channel
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
      it { expect(service).to be_able_to :manage_contacts_and_mailing_by_business_plan, organization }
      it { expect(service).to be_able_to :manage_contacts_and_mailing_by_business_plan, current_user }

      %w[new trial_suspended deactivated suspended].each do |status|
        it "#{status} subscription for organization" do
          subscription.update(service_status: status)
          expect(service).not_to be_able_to :manage_contacts_and_mailing_by_business_plan, organization
        end

        it "#{status} subscription for user" do
          subscription.update(service_status: status)
          expect(service).not_to be_able_to :manage_contacts_and_mailing_by_business_plan, current_user
        end
      end

      it 'split_revenue organization for organization' do
        organization.update!(split_revenue_plan: true)
        expect(service).to be_able_to :manage_contacts_and_mailing_by_business_plan, organization
      end

      it 'split_revenue organization for user' do
        organization.update(split_revenue_plan: true)
        expect(service).to be_able_to :manage_contacts_and_mailing_by_business_plan, current_user
      end
    end
  end
end
