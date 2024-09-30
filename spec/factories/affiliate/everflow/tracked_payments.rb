# frozen_string_literal: true
FactoryBot.define do
  factory :affiliate_everflow_tracked_payment, class: 'Affiliate::Everflow::TrackedPayment' do
    association :payment_transaction, factory: :stubbed_stripe_transaction
    association :purchased_item, factory: :stripe_service_subscription
    association :affiliate_everflow_transaction, factory: :affiliate_everflow_transaction
  end
  factory :aa_stub_affiliate_everflow_tracked_payments, parent: :affiliate_everflow_tracked_payment
end
