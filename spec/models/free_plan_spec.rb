# frozen_string_literal: true
require 'spec_helper'

describe FreePlan do
  let(:free_plan) { create(:free_plan) }
  let(:user) { create(:user) }

  describe '.scopes' do
    before do
      free_plan
    end

    describe '.not_archived' do
      it { expect { described_class.not_archived }.not_to raise_error }
    end
  end

  describe '#free_subscription_params' do
    it { expect { free_plan.free_subscription_params }.not_to raise_error }

    it { expect(free_plan.free_subscription_params).to be_present }
  end

  describe '#update_free_subscriptions_duration' do
    let(:free_subscription) { create(:free_subscription) }
    let(:free_plan) { free_subscription.free_plan }

    it 'updates free subscriptions' do
      expect do
        free_plan.update(duration_type: :duration_interval, start_at: 3.days.from_now, end_at: 5.days.from_now)
        free_subscription.reload
      end.to not_raise_error.and change(free_subscription, :end_at)
    end
  end
end
