# frozen_string_literal: true
require 'spec_helper'

describe FreeSubscription do
  let(:free_subscription) { create(:free_subscription) }
  let(:user) { create(:user) }

  describe '.scopes' do
    before do
      free_subscription
    end

    describe '.not_stopped' do
      it { expect { described_class.not_stopped }.not_to raise_error }
    end

    describe '.in_action' do
      it { expect { described_class.in_action }.not_to raise_error }
    end

    describe '.with_features' do
      it { expect { described_class.with_features(:replays, :documents) }.not_to raise_error }
    end
  end

  describe '#starts_at' do
    let(:free_subscription) { build(:free_subscription) }

    it { expect { free_subscription.starts_at }.not_to raise_error }
  end

  describe '#user_email=' do
    let(:free_subscription) { build(:free_subscription) }

    it { expect { free_subscription.user_email = user.email }.not_to raise_error }

    it 'assignes user' do
      expect do
        free_subscription.user_email = user.email
      end.to change(free_subscription, :user_id).to(user.id)
    end
  end
end
