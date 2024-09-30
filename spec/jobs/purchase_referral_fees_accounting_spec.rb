# frozen_string_literal: true

require 'spec_helper'

describe PurchaseReferralFeesAccounting do
  let(:payment_transaction) { create(:real_stripe_transaction, amount: 3000) }
  let(:session) { payment_transaction.purchased_item }
  let(:master_user) { create(:user) }

  before do
    create(:ffmpegservice_account)
    create(:referral, master_user: master_user, user: payment_transaction.user)
  end

  it { expect(LogTransaction.count).to eq(0) }

  it 'not fail ' do
    described_class.perform(session.id, payment_transaction.id, nil)
    expect(Plutus::Amount.last.amount).to eq(0.45)
  end

  it 'does not fail' do
    described_class.perform(session.id, payment_transaction.id, nil)
    expect(LogTransaction.count).to eq(1)
  end
end
