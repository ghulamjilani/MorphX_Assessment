# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe ServiceSubscriptionJobs::SuspendedMailerJob do
  let(:organization) { create(:organization_with_subscription) }
  let(:subscription) { organization.user.service_subscription }

  before do
    subscription.update(current_period_end: 2.days.ago)
    subscription.grace!
    subscription.suspended!
    create(:feature_parameter, plan_package: subscription.plan_package,
                               plan_feature: create(:grace_days_plan_feature), value: 1)
    create(:feature_parameter, plan_package: subscription.plan_package,
                               plan_feature: create(:suspended_days_plan_feature), value: 1)
  end

  describe 'suspended_started email' do
    before do
      mailer = double
      allow(mailer).to receive(:deliver_now)
      allow(ServiceSubscriptionsMailer).to receive(:suspended_started).with(subscription.id).and_return(mailer)
    end

    it 'send' do
      Timecop.travel(subscription.suspended_at + 1.hour) do
        Sidekiq::Testing.inline! { described_class.perform_async }
        expect(ServiceSubscriptionsMailer).to have_received(:suspended_started).with(subscription.id)
      end
    end
  end
end
