# frozen_string_literal: true

require 'spec_helper'

describe PendingRefundsController do
  before do
    sign_in current_user, scope: :user
  end

  let(:current_user) { create(:participant).user }
  let(:real_stripe_transaction) { create(:real_stripe_transaction, user: current_user) }
  let(:pending_refund) { create(:pending_refund, user: current_user, payment_transaction: real_stripe_transaction) }

  before do
    session = pending_refund.payment_transaction.purchased_item
    session.immersive_participants << current_user.participant
    expect(SessionParticipation.count).to eq(1)
  end

  describe 'GET :get_system_credit' do
    before do
      expect(current_user.participant.system_credit_balance).to eq(0)
    end

    context 'when given valid pending refund request' do
      it 'works' do
        get :get_system_credit, params: { id: pending_refund.id }
        expect(response).to be_redirect

        expect(SessionParticipation.count).to eq(0)
        expect(current_user.participant.reload.system_credit_balance).to eq(pending_refund.payment_transaction.amount)
      end
    end

    context 'when given valid pending refund request' do
      it 'fails gracefully' do
        get :get_system_credit, params: { id: 12_345_678 }
        expect(response).to be_redirect
        actual = flash.now[:notice]
        expect(actual).to be_present
      end
    end
  end

  describe 'GET :get_money' do
    it 'works' do
      get :get_money, params: { id: pending_refund.id }
      expect(response).to be_redirect
      expect(SessionParticipation.count).to eq(0)
      expect(PaymentTransaction.count).to eq(1)
      expect(PaymentTransaction.last).to be_refund
    end
  end
end
