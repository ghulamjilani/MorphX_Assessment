# frozen_string_literal: true
FactoryBot.define do
  factory :stubbed_stripe_transaction, class: 'PaymentTransaction' do
    user { FactoryBot.create(:participant).user }
    provider { 'stripe' }
    status { 'succeeded' }
    pid { SecureRandom.hex(3) }
    authorization_code { "ABCD#{rand(999)}" }
    association :purchased_item, factory: :immersive_session
    credit_card_last_4 { 1234 }
    card_type { 'Visa' }
    type { TransactionTypes::IMMERSIVE }
    amount { rand(20..54) * 100 }
  end

  factory :real_stripe_transaction, class: 'PaymentTransaction' do
    user
    association :purchased_item, factory: :immersive_session
    provider { 'stripe' }
    type { TransactionTypes::IMMERSIVE }
    amount { rand(20..54) * 100 }
    after(:build) do |transaction|
      @stripe_test_helper = StripeMock.create_test_helper
      charge = Stripe::Charge.create(
        {
          amount: transaction.amount,
          currency: 'usd',
          description: "Obtain #{transaction.type} for #{transaction.purchased_item.class.name}##{transaction.purchased_item.id}",
          source: @stripe_test_helper.generate_card_token
        }
      )

      transaction.pid = charge.id
      transaction.credit_card_last_4 = charge.source.last4
      transaction.card_type = charge.source.brand
      transaction.status = charge.status
    end
  end

  factory :aa_stub_payment_transactions, parent: :stubbed_stripe_transaction
end
