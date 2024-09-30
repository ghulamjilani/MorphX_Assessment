# frozen_string_literal: true
require 'spec_helper'

describe StripeDb::ServiceSubscription do
  describe 'emails' do
    it 'send activate email' do
      s = create(:stripe_service_subscription, status: :new)
      mailer = double
      allow(mailer).to receive(:deliver_later)
      expect(ServiceSubscriptionsMailer).to receive(:activated).once.and_return(mailer)
      s.active!
    end

    it 'send trial email' do
      s = create(:stripe_service_subscription, status: :new)
      mailer = double
      allow(mailer).to receive(:deliver_later)
      expect(ServiceSubscriptionsMailer).to receive(:trial_started).once.and_return(mailer)
      s.trialing!
    end

    it 'send request cancellation email' do
      s = create(:stripe_service_subscription, status: :active)
      mailer = double
      allow(mailer).to receive(:deliver_later)
      expect(ServiceSubscriptionsMailer).to receive(:cancellation_requested).once.and_return(mailer)
      s.update(canceled_at: Time.now)
    end

    it 'not send request cancellation email' do
      s = create(:stripe_service_subscription, status: :trialing)
      expect(ServiceSubscriptionsMailer).not_to receive(:cancellation_requested)
      s.update(canceled_at: Time.now)
    end

    it 'set grace_at to datetime' do
      s = create(:stripe_service_subscription, service_status: :active)
      expect { s.grace! }.to change(s, :grace_at).from(nil).to(Time)
    end

    it 'set suspended_at to datetime' do
      s = create(:stripe_service_subscription, service_status: :grace)
      expect { s.suspended! }.to change(s, :suspended_at).from(nil).to(Time)
    end

    describe 'cancelation' do
      let(:subscription) { build(:stripe_service_subscription) }

      before do
        allow_any_instance_of(described_class).to receive_message_chain(:stripe_item, :delete) { true }
      end

      # it 'send canceled email' do
      #   subscription.update(status: :active)
      #   mailer = double
      #   allow(mailer).to receive(:deliver_later)
      #   expect(ServiceSubscriptionsMailer).to receive(:canceled).once.and_return(mailer)
      #   subscription.canceled!
      # end
      #
      # it 'send trial canceled email' do
      #   subscription.update(status: 'trialing')
      #   mailer = double
      #   allow(mailer).to receive(:deliver_later)
      #   expect(ServiceSubscriptionsMailer).to receive(:canceled).once.and_return(mailer)
      #   subscription.canceled!
      # end
    end

    describe 'deactivate' do
      let(:subscription) { build(:stripe_service_subscription) }

      before do
        allow_any_instance_of(described_class).to receive_message_chain(:stripe_item, :delete) { true }
      end

      it 'send deactivated email' do
        subscription.update(status: :active)
        mailer = double
        allow(mailer).to receive(:deliver_later)
        expect(ServiceSubscriptionsMailer).to receive(:deactivated).once.and_return(mailer)
        subscription.deactivate!
      end

      it 'send performs invitation cancellation' do
        subscription.update(status: :active)
        allow(ServiceSubscriptionJobs::CancelUnacceptedInvitationsJob).to receive(:perform_async)
        expect(ServiceSubscriptionJobs::CancelUnacceptedInvitationsJob).to receive(:perform_async).once
        subscription.deactivate!
      end
    end

    describe '#feature_value' do
      let(:stripe_service_subscription) { create(:stripe_service_subscription) }

      it { expect { stripe_service_subscription.feature_value(PlanFeature::CODES.sample) }.not_to raise_error }

      it { expect(stripe_service_subscription.feature_value(PlanFeature::CODES.sample)).to be_blank }

      context 'when feature parameter exists' do
        let(:feature_parameter) do
          create(:feature_parameter,
                 plan_package: stripe_service_subscription.plan_package,
                 plan_feature: create(:manage_creators_plan_feature), value: true)
        end
        let(:code) { feature_parameter.plan_feature.code }

        it { expect { stripe_service_subscription.feature_value(code) }.not_to raise_error }

        it { expect(stripe_service_subscription.feature_value(code)).to be_present }
      end
    end
  end
end
