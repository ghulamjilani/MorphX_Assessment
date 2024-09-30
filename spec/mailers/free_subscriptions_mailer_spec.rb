# frozen_string_literal: true

require 'spec_helper'

describe FreeSubscriptionsMailer do
  let(:free_subscription_id) { create(:free_subscription).id }

  describe '#invite' do
    it 'does not fail' do
      expect { described_class.invite(free_subscription_id).deliver }.not_to raise_error
    end
  end

  describe '#going_to_be_finished' do
    it 'does not fail' do
      expect { described_class.going_to_be_finished(free_subscription_id).deliver }.not_to raise_error
    end
  end

  describe '#ended' do
    it 'does not fail' do
      expect { described_class.ended(free_subscription_id).deliver }.not_to raise_error
    end
  end
end
