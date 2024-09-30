# frozen_string_literal: true

require 'spec_helper'

describe MailerHelper do
  let(:helper1) do
    helper = Object.new
    helper.extend described_class
    helper
  end

  describe '#eligible_for_system_credit_refund?(pending_refund)' do
    let(:session) { create(:immersive_session) }
    let(:current_user) { create(:user) }

    context 'when given paid participant' do
      it 'returns true' do
        session.immersive_participants << current_user.create_participant
        payment_transaction = create(:real_stripe_transaction, purchased_item: session, user: current_user)
        pending_refund = create(:pending_refund, user: current_user, payment_transaction: payment_transaction)
        expect(helper1.eligible_for_system_credit_refund?(pending_refund, current_user)).to be true
      end
    end

    context 'when given paid co-presenter' do
      it 'returns false' do
        session.co_presenters << create(:presenter, user: current_user)
        payment_transaction = create(:real_stripe_transaction, purchased_item: session, user: current_user)
        pending_refund = create(:pending_refund, user: current_user, payment_transaction: payment_transaction)
        expect(helper1.eligible_for_system_credit_refund?(pending_refund, current_user)).to be false
      end
    end
  end

  describe '.wrap_content_urls' do
    let(:content) do
      "#{Forgery(:lorem_ipsum).words(5,
                                     random: true)} https://#{Forgery(:internet).domain_name} #{Forgery(:lorem_ipsum).words(
                                       5, random: true
                                     )}"
    end

    it { expect { helper1.wrap_content_urls(content) }.not_to raise_error }
  end
end
