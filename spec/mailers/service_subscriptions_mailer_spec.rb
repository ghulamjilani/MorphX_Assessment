# frozen_string_literal: true

require 'spec_helper'

describe ServiceSubscriptionsMailer do
  let(:log_transaction) { create(:purchased_service_subscription_log_transaction) }
  let(:stripe_service_subscription) { create(:stripe_service_subscription, suspended_at: 5.minutes.ago, current_period_end: 5.minutes.ago) }

  describe '#receipt' do
    it 'does not fail' do
      expect { described_class.receipt(log_transaction.id).deliver }.not_to raise_error
    end

    it 'sends email' do
      expect do
        described_class.receipt(log_transaction.id).deliver
      end.to change(ActionMailer::Base.deliveries, :count)
    end
  end

  describe '#trial_started' do
    it 'does not fail' do
      expect { described_class.trial_started(stripe_service_subscription.id).deliver }.not_to raise_error
    end

    it 'sends email' do
      expect do
        described_class.trial_started(stripe_service_subscription.id).deliver
      end.to change(ActionMailer::Base.deliveries, :count)
    end
  end

  describe '#trial_ended' do
    it 'does not fail' do
      expect { described_class.trial_ended(stripe_service_subscription.id).deliver }.not_to raise_error
    end

    it 'sends email' do
      expect do
        described_class.trial_ended(stripe_service_subscription.id).deliver
      end.to change(ActionMailer::Base.deliveries, :count)
    end
  end

  describe '#activated' do
    it 'does not fail' do
      expect { described_class.activated(stripe_service_subscription.id).deliver }.not_to raise_error
    end

    it 'sends email' do
      expect do
        described_class.activated(stripe_service_subscription.id).deliver
      end.to change(ActionMailer::Base.deliveries, :count)
    end
  end

  describe '#cancellation_requested' do
    it 'does not fail' do
      expect { described_class.cancellation_requested(stripe_service_subscription.id).deliver }.not_to raise_error
    end

    it 'sends email' do
      expect do
        described_class.cancellation_requested(stripe_service_subscription.id).deliver
      end.to change(ActionMailer::Base.deliveries, :count)
    end
  end

  describe '#canceled' do
    it 'does not fail' do
      expect { described_class.canceled(stripe_service_subscription.id).deliver }.not_to raise_error
    end

    it 'sends email' do
      expect do
        described_class.canceled(stripe_service_subscription.id).deliver
      end.to change(ActionMailer::Base.deliveries, :count)
    end
  end

  describe '#trial_finished_payment_failed' do
    it 'does not fail' do
      expect { described_class.trial_finished_payment_failed(stripe_service_subscription.id).deliver }.not_to raise_error
    end

    it 'sends email' do
      expect do
        described_class.trial_finished_payment_failed(stripe_service_subscription.id).deliver
      end.to change(ActionMailer::Base.deliveries, :count)
    end
  end

  describe '#grace_started_payment_failed' do
    it 'does not fail' do
      expect { described_class.grace_started_payment_failed(stripe_service_subscription.id).deliver }.not_to raise_error
    end

    it 'sends email' do
      expect do
        described_class.grace_started_payment_failed(stripe_service_subscription.id).deliver
      end.to change(ActionMailer::Base.deliveries, :count)
    end
  end

  describe '#suspended_started' do
    it 'does not fail' do
      expect { described_class.suspended_started(stripe_service_subscription.id).deliver }.not_to raise_error
    end

    it 'sends email' do
      expect do
        described_class.suspended_started(stripe_service_subscription.id).deliver
      end.to change(ActionMailer::Base.deliveries, :count)
    end
  end

  describe '#deactivated' do
    it 'does not fail' do
      expect { described_class.deactivated(stripe_service_subscription.id).deliver }.not_to raise_error
    end

    it 'sends email' do
      expect do
        described_class.deactivated(stripe_service_subscription.id).deliver
      end.to change(ActionMailer::Base.deliveries, :count)
    end
  end
end
