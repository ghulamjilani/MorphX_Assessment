# frozen_string_literal: true
FactoryBot.define do
  factory :payout do
    user
    amount_cents { 120 }
    provider { 'stripe' }
    reference { 'test payout' }
    status { 'pending' }
  end
  factory :paid_stripe_payout, parent: :payout do
    association :user, factory: :user_with_stripe_connect_account
    after(:create) do |payout|
      st = Stripe::Transfer.create(
        amount: payout.amount_cents,
        currency: payout.amount_currency,
        destination: payout.user.payout_methods.first.connect_account.account_id,
        description: payout.reference
      )
      payout.pid = st.id
      payout.status = 'paid'
      payout.save
    end
  end
  factory :aa_stub_payouts, parent: :payout
end
