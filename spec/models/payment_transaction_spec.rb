# frozen_string_literal: true
require 'spec_helper'

describe PaymentTransaction do
  subject(:transaction) { build(:real_stripe_transaction) }

  PaymentTransaction::Statuses::ALL.each do |status|
    transaction_status_name = "transaction_status_#{status}".to_sym
    let(transaction_status_name) { create(:stubbed_stripe_transaction, status: status) }
  end
  let(:session) { create(:published_session) }
  let(:user) { create(:user) }
  let(:real_stripe_transaction) { create(:real_stripe_transaction) }
  let(:real_stripe_transaction2) do
    create(:real_stripe_transaction,
           purchased_item: session,
           amount: 122,
           tax_cents: 12,
           credit_card_last_4: 1234,
           status: PaymentTransaction::Statuses::SUCCEEDED,
           user: user)
  end
  let(:stubbed_stripe_transaction) { create(:stubbed_stripe_transaction, status: nil) }
  let(:stripe_transaction_no_credit_card) do
    create(:stubbed_stripe_transaction, credit_card_last_4: nil, payer_email: 'vasya@example.com')
  end

  it 'touches checked_at on any state change' do
    checked_at_was = real_stripe_transaction.reload.checked_at
    expect(checked_at_was).not_to be_nil
  end

  # Relationships
  it { expect(transaction).to belong_to(:purchased_item) }
  it { expect(transaction).to belong_to(:user) }
  it { expect(transaction).to have_one(:pending_refund) }
  it { expect(transaction).to have_many(:log_transactions) }

  # Validations
  it { is_expected.to validate_inclusion_of(:type).in_array(::TransactionTypes::ALL) }

  context 'when type is TransactionTypes::IMMERSIVE' do
    before { allow(transaction).to receive(:type).and_return(TransactionTypes::IMMERSIVE) }

    it { expect(transaction).to validate_presence_of(:purchased_item) }
  end

  context 'when type is TransactionTypes::LIVESTREAM' do
    before { allow(transaction).to receive(:type).and_return(TransactionTypes::LIVESTREAM) }

    it { expect(transaction).to validate_presence_of(:purchased_item) }
  end

  context 'when type is TransactionTypes::RECORDED' do
    before { allow(transaction).to receive(:type).and_return(TransactionTypes::RECORDED) }

    it { is_expected.to validate_presence_of(:purchased_item) }
  end

  context 'when status changed' do
    before { allow(transaction).to receive(:status_changed?).and_return(true) }

    it { expect(transaction).to callback(:set_checked_at).before(:validation) }
  end

  describe '-> instance methods' do
    let(:stripe_transaction) { create(:stubbed_stripe_transaction) }
    let(:paypal_transaction) { create(:stubbed_stripe_transaction, provider: 'paypal') }

    context 'when provider is paypal' do
      it '#paypal?' do
        expect(paypal_transaction.send('paypal?')).to be_truthy
      end

      it '#stripe?' do
        expect(paypal_transaction.send('stripe?')).to be_falsey
      end
    end

    context 'when provider is stripe' do
      it '#paypal?' do
        expect(stripe_transaction.send('paypal?')).to be_falsey
      end

      it '#stripe?' do
        expect(stripe_transaction.send('stripe?')).to be_truthy
      end
    end

    PaymentTransaction::Statuses::ALL.each do |status|
      transaction_status_name = "transaction_status_#{status}"
      wrong_status = (PaymentTransaction::Statuses::ALL - [status]).sample
      transaction_wrong_status_name = "transaction_status_#{wrong_status}"
      # rubocop:disable Security/Eval
      it "##{status}?" do
        expect(eval(transaction_status_name).send("#{status}?")).to be_truthy
        expect(eval(transaction_wrong_status_name).send("#{status}?")).to be_falsey
      end
      # rubocop:enable Security/Eval
    end

    it '#total_amount' do
      expect(real_stripe_transaction.total_amount).to be_truthy
      expect(real_stripe_transaction.total_amount).to be_an(Integer)
    end

    it '#tax_amount' do
      expect(real_stripe_transaction.tax_amount).to be_truthy
      expect(real_stripe_transaction.tax_amount).to be_a(Float)
    end

    it '#set_initial_status' do
      expect(stubbed_stripe_transaction.set_initial_status).to be_truthy
      expect(stubbed_stripe_transaction.status).to eq('unauthorized')
    end

    it '#credit_card?' do
      expect(stubbed_stripe_transaction.credit_card?).to eq(true)
      expect(stripe_transaction_no_credit_card.credit_card?).to eq(false)
    end

    it '#receipt_title' do
      expect(stubbed_stripe_transaction.receipt_title).to eq('Stripe ID')
      expect(stripe_transaction_no_credit_card.receipt_title).to eq('PayPal Email')
    end

    it '#receipt_value' do
      expect(stubbed_stripe_transaction.receipt_value == stubbed_stripe_transaction.pid).to be true
      expect(stripe_transaction_no_credit_card.receipt_value == stripe_transaction_no_credit_card.payer_email).to be true
    end

    it '#system_credit_refund!' do
      refund_amount = 25
      expect do
        expect(stubbed_stripe_transaction.system_credit_refund!(refund_amount)).to be true
      end.to change(LogTransaction, :count).by(1)
                                           .and change { Plutus::Entry.count }.by(1)
    end

    describe '#cancel_stripe!' do
      let(:stripe_transaction) { create(:real_stripe_transaction) }
      let(:certain_amount) { 25 }

      it 'creates MONEY_REFUND log transaction ' do
        expect do
          stripe_transaction.cancel_stripe!(certain_amount)
        end.to change {
          stripe_transaction.user.log_transactions.where(type: LogTransaction::Types::MONEY_REFUND).count
        }.by(1)
      end
    end

    describe 'cancellation methods' do
      let(:paypal_transaction) { create(:stubbed_stripe_transaction, provider: 'paypal') }
      let(:stripe_transaction) { create(:stubbed_stripe_transaction) }
      let(:real_stripe_transaction) { create(:real_stripe_transaction) }

      before do
        allow(PayPal::SDK::REST::DataTypes::Sale)
          .to receive(:find)
          .and_return(PayPal::SDK::REST::DataTypes::Sale.new(id: '123456'))

        allow_any_instance_of(PayPal::SDK::REST::DataTypes::Sale)
          .to receive(:refund)
          .and_return(PayPal::SDK::REST::DataTypes::Refund.new(id: '1234567'))
      end

      describe '#cancel_paypal!' do
        it 'creates MONEY_REFUND log transaction ' do
          expect { paypal_transaction.cancel_paypal! }.to change {
            paypal_transaction.user.log_transactions
                              .where(
                                type: LogTransaction::Types::MONEY_REFUND,
                                abstract_session: paypal_transaction.purchased_item
                              ).count
          }.by(1)
        end

        it 'changes transaction status to PaymentTransaction::Statuses::REFUND' do
          paypal_transaction.cancel_paypal! paypal_transaction.total_amount
          expect(paypal_transaction.status).to eq(PaymentTransaction::Statuses::REFUND)
        end
      end

      describe '#money_refund!' do
        context 'when transaction is paypal' do
          it 'cancells paypal' do
            expect(paypal_transaction).to receive(:cancel_paypal!)
            paypal_transaction.money_refund!
          end

          it 'sends an email with money refund receipt' do
            paypal_transaction.money_refund!
            expect(ApplicationMailDeliveryJob).to(
              have_been_enqueued.with(
                'Mailer',
                'money_refund_receipt',
                'deliver_now',
                args: [
                  paypal_transaction.user.id,
                  paypal_transaction.log_transactions.where(type: LogTransaction::Types::MONEY_REFUND).last.id
                ]
              )
            )
          end
        end

        context 'when transaction is stripe' do
          it 'cancells stripe' do
            expect(real_stripe_transaction).to receive(:cancel_stripe!)
            real_stripe_transaction.money_refund!
          end

          it 'sends an email with money refund receipt' do
            real_stripe_transaction.money_refund!
            expect(ApplicationMailDeliveryJob).to(
              have_been_enqueued.with(
                'Mailer',
                'money_refund_receipt',
                'deliver_now',
                args:
                  [
                    real_stripe_transaction.user.id,
                    real_stripe_transaction.log_transactions.where(type: LogTransaction::Types::MONEY_REFUND).last.id
                  ]
              )
            )
          end
        end

        it 'creates new Plutus::Entry' do
          expect do
            paypal_transaction.money_refund!
          end.to change { Plutus::Entry.count }.by(1)
        end
      end
    end

    describe '#image_url' do
      let(:stripe_credit_card) { create(:stubbed_stripe_transaction) }
      let(:paypal_no_credit_card) { create(:stubbed_stripe_transaction, provider: 'paypal', credit_card_last_4: '') }
      let(:stripe_no_credit_card) { create(:stubbed_stripe_transaction, credit_card_last_4: '') }

      context 'when credit card' do
        it 'returns visa svg' do
          expect(stripe_credit_card.image_url == 'cards/visa.svg').to eq(true)
        end
      end

      context 'when paypal and no credit card' do
        it 'returns paypal png' do
          expect(paypal_no_credit_card.image_url).to eq('https://assets.braintreegateway.com/payment_method_logo/paypal.png?environment=sandbox')
        end
      end

      context 'when stripe and no credit card' do
        it 'returns empty string' do
          expect(stripe_no_credit_card.image_url).to eq('')
        end
      end
    end

    describe '#refunds' do
      let(:paypal_transaction) { create(:stubbed_stripe_transaction, provider: 'paypal') }
      let(:stripe_transaction) { create(:stubbed_stripe_transaction) }

      context 'when stripe' do
        it 'returns an array of refunds' do
          expect(stripe_transaction.refunds).to be_a(Stripe::ListObject)
        end
      end

      context 'when paypal' do
        it 'returns an array of refunds' do
          allow(PayPal::SDK::REST::DataTypes::Sale)
            .to receive(:find)
            .and_return(PayPal::SDK::REST::DataTypes::Sale.new)

          allow(PayPal::SDK::REST::DataTypes::Payment)
            .to receive(:find)
            .and_return(PayPal::SDK::REST::DataTypes::Payment.new)

          expect(paypal_transaction.refunds).to be_truthy
        end
      end
    end
  end
end
