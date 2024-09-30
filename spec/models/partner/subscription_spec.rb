# frozen_string_literal: true
require 'spec_helper'

describe Partner::Subscription do
  let(:partner_subscription) { create(:partner_subscription) }

  describe '#sanitize_customer_email' do
    it { expect { partner_subscription.send :sanitize_customer_email }.not_to raise_error }
  end
end
