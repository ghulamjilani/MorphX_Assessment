# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe ServiceSubscriptionJobs::GraceCheckJob do
  let(:organization) { create(:organization_with_subscription) }
  let(:subscription) { organization.user.service_subscription }

  before do
    subscription.grace!
    create(:feature_parameter, plan_package: subscription.plan_package,
                               plan_feature: create(:grace_days_plan_feature), value: 14)
  end

  it 'does not suspend' do
    Timecop.travel(subscription.grace_at + 1.hour) do
      Sidekiq::Testing.inline! { described_class.perform_async }
      expect(subscription.reload.service_status).to eq('grace')
    end
  end

  it 'suspend' do
    Timecop.travel(subscription.grace_at + 15.days) do
      Sidekiq::Testing.inline! { described_class.perform_async }
      expect(subscription.reload.service_status).to eq('suspended')
    end
  end

  # describe 'mail' do
  #   before do
  #     allow(mailer = double).to receive(:deliver_later)
  #     allow(ServiceSubscriptionsMailer).to receive(:grace_started_payment_failed) { mailer }
  #   end

  #   it 'resend email' do
  #     Timecop.travel(subscription.grace_at + 7.days) do
  #       Sidekiq::Testing.inline! { described_class.perform_async }
  #       expect(ServiceSubscriptionsMailer).to have_received(:grace_started_payment_failed)
  #     end
  #   end
  # end
end
