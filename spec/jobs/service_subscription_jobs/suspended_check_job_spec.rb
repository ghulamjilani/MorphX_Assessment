# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe ServiceSubscriptionJobs::SuspendedCheckJob do
  let(:organization) { create(:organization_with_subscription) }
  let(:subscription) { organization.user.service_subscription }

  before do
    subscription.update(current_period_end: Time.zone.now - 2.days)
    subscription.grace!
    subscription.suspended!
    create(:feature_parameter, plan_package: subscription.plan_package,
                               plan_feature: create(:grace_days_plan_feature), value: 1)
    create(:feature_parameter, plan_package: subscription.plan_package,
                               plan_feature: create(:suspended_days_plan_feature), value: 1)
  end

  it 'does not suspend' do
    Timecop.travel(subscription.suspended_at + 1.hour) do
      Sidekiq::Testing.inline! { described_class.perform_async }
      expect(subscription.reload.service_status).to eq('suspended')
    end
  end

  describe 'deactivate' do
    before do
      stripe_item = double
      allow(Stripe::Subscription).to receive(:retrieve).and_return(stripe_item)
      allow(stripe_item).to receive(:delete).and_return(true)
    end

    it 'suspended ends' do
      Timecop.travel(subscription.suspended_at + 25.hours) do
        Sidekiq::Testing.inline! { described_class.perform_async }
        expect(subscription.reload.service_status).to eq('deactivated')
      end
    end

    # it 'enqueue remove content job' do
    #   Timecop.travel(subscription.suspended_at + 25.hours) do
    #     allow(ServiceSubscriptionJobs::RemoveContentJob).to receive(:perform_async).with(subscription.id)
    #     Sidekiq::Testing.inline! { described_class.perform_async }
    #     expect(ServiceSubscriptionJobs::RemoveContentJob).to have_received(:perform_async).with(subscription.id)
    #   end
    # end

    describe 'deactivated emails' do
      before do
        mailer = double
        allow(mailer).to receive(:deliver_later)
        allow(ServiceSubscriptionsMailer).to receive(:deactivated).with(subscription.id).and_return(mailer)
      end

      it 'send' do
        Timecop.travel(subscription.suspended_at + 25.hours) do
          Sidekiq::Testing.inline! { described_class.perform_async }
          expect(ServiceSubscriptionsMailer).to have_received(:deactivated).with(subscription.id)
        end
      end
    end
  end
end
