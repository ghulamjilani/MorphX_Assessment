# frozen_string_literal: true
require 'spec_helper'

describe LogTransaction do
  describe '#as_html' do
    let(:session) { create(:immersive_session) }

    [LogTransaction::Types::PURCHASED_CHANNEL_SUBSCRIPTION, LogTransaction::Types::PURCHASED_CHANNEL_GIFT_SUBSCRIPTION,
     LogTransaction::Types::SOLD_CHANNEL_SUBSCRIPTION, LogTransaction::Types::SOLD_CHANNEL_GIFT_SUBSCRIPTION,
     LogTransaction::Types::PURCHASED_SERVICE_SUBSCRIPTION].each do |type|
      context "given #{type}" do
        it { expect { create(:"#{type}_log_transaction").as_html.inspect }.not_to raise_error }
      end
    end

    context 'when given PURCHASED_INTERACTIVE_ABSTRACT_SESSION' do
      it 'works' do
        expect do
          described_class.new(abstract_session: session,
                              type: LogTransaction::Types::PURCHASED_INTERACTIVE_ABSTRACT_SESSION, data: { credit_card_number: '1235678' }).as_html.inspect
        end.not_to raise_error
      end
    end

    context 'when given PAID_FOR_CO_PRESENTER' do
      let(:presenter) { create(:presenter) }

      it 'works' do
        expect do
          described_class.new(abstract_session: session, type: LogTransaction::Types::PAID_FOR_CO_PRESENTER,
                              data: { presenter_id: presenter.id }).as_html.inspect
        end.not_to raise_error
      end
    end

    context 'when given LIVE_OPT_OUT_FROM_ABSTRACT_SESSION_AFTER_PAYING' do
      let(:session) { create(:immersive_session) }

      it 'works' do
        expect do
          described_class.new(abstract_session: session,
                              type: LogTransaction::Types::LIVE_OPT_OUT_FROM_ABSTRACT_SESSION_AFTER_PAYING, data: {}).as_html.inspect
        end.not_to raise_error
      end
    end

    context 'when given MONEY_REFUND' do
      let(:session) { create(:immersive_session) }

      it 'works' do
        expect do
          described_class.new(abstract_session: session,
                              data: {
                                transaction_id: '1231455567',
                                status: 'voided',
                                credit_card_number: ('*' * 12) + 1234.to_s
                              },
                              amount: 12.99, type: LogTransaction::Types::MONEY_REFUND).as_html.inspect
        end.not_to raise_error
      end
    end

    context 'when given SYSTEM_CREDIT_REFUND' do
      let(:session) { create(:immersive_session) }

      it 'works' do
        expect do
          described_class.new(abstract_session: session,
                              data: {
                                credit_was: -10,
                                credit: 10
                              },
                              amount: 20, type: LogTransaction::Types::SYSTEM_CREDIT_REFUND).as_html.inspect
        end.not_to raise_error
      end
    end
  end
end
