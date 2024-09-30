# frozen_string_literal: true
require 'spec_helper'

describe PendingRefund do
  it 'does not leave orphaned records' do
    create(:pending_refund)

    expect(PaymentTransaction.count).to eq(1)

    PaymentTransaction.last.destroy

    expect(described_class.count).to eq(0)
    expect(PaymentTransaction.count).to eq(0)
  end
end
