# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe PayoutJob do
  let(:presenter) { create(:presenter, user: create(:user_with_stripe_connect_account)) }
  let(:channel) { create(:listed_channel, organization: create(:organization, user: presenter.user)) }
  let(:session) { create(:immersive_session, channel: channel) }
  let(:payment_transaction) { create(:real_stripe_transaction, purchased_item: session) }
  let(:date) { Date.new(Time.zone.now.year, Time.zone.now.month, 20).to_datetime }

  before do
    create(:log_transaction,
           user: payment_transaction.user, type: LogTransaction::Types::PURCHASED_INTERACTIVE_ABSTRACT_SESSION, abstract_session: session, image_url: payment_transaction.image_url,
           data: { credit_card_number: ('*' * 12) + payment_transaction.credit_card_last_4.to_s, card_type: payment_transaction.card_type },
           amount: -payment_transaction.total_amount / 100.0, payment_transaction: payment_transaction, created_at: date - 20.days)
    amount = (payment_transaction.amount * session.presenter.user.profit_margin_percent / 100.0 / 100.0).round(2)
    create(:log_transaction,
           user: session.organizer, type: LogTransaction::Types::NET_INCOME, abstract_session: session, data: { access_type: :immersive },
           amount: amount, payment_transaction: payment_transaction, created_at: date - 20.days)
  end

  it 'does not fail' do
    Timecop.travel date do
      expect(Payout.count).to be_zero
    end
  end

  it 'does not' do
    Timecop.travel date do
      expect { Sidekiq::Testing.inline! { described_class.perform_async } }.not_to raise_error
    end
  end

  it 'does' do
    Timecop.travel date do
      Sidekiq::Testing.inline! { described_class.perform_async }
      expect(Payout.count).to eq(1)
    end
  end
end
