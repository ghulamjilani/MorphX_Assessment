# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe ServiceSubscriptionJobs::TrialSuspendedCheckJob do
  let(:organization) { create(:organization_with_subscription) }
  let(:subscription) { organization.user.service_subscription }

  before do
    subscription.update(current_period_end: 2.days.ago)
    subscription.trial_suspended!
    create(:feature_parameter, plan_package: subscription.plan_package,
                               plan_feature: create(:trial_suspended_days_plan_feature), value: 1)
  end

  it 'does not deactivate' do
    Timecop.travel(subscription.trial_suspended_at + 1.hour) do
      Sidekiq::Testing.inline! { described_class.perform_async }
      expect(subscription.reload.service_status).to eq('trial_suspended')
    end
  end

  describe 'deactivate' do
    before do
      stripe_item = double
      allow(Stripe::Subscription).to receive(:retrieve).and_return(stripe_item)
      allow(stripe_item).to receive(:delete).and_return(true)
    end

    it 'trial suspended ends' do
      Timecop.travel(subscription.trial_suspended_at + 25.hours) do
        Sidekiq::Testing.inline! { described_class.perform_async }
        expect(subscription.reload.service_status).to eq('deactivated')
      end
    end
  end
end
