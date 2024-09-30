# frozen_string_literal: true
FactoryBot.define do
  factory :log_transaction do
    user
    association :abstract_session, factory: :immersive_session
    type { LogTransaction::Types::SYSTEM_CREDIT_REFUND }
    amount { 12.0 }
    data { { credit_was: -24, credit: -12 } }
  end

  # Channel Subscriptions
  [LogTransaction::Types::PURCHASED_CHANNEL_SUBSCRIPTION, LogTransaction::Types::PURCHASED_CHANNEL_GIFT_SUBSCRIPTION,
   LogTransaction::Types::SOLD_CHANNEL_SUBSCRIPTION, LogTransaction::Types::SOLD_CHANNEL_GIFT_SUBSCRIPTION].each do |type|
    factory :"#{type}_log_transaction", parent: :log_transaction do
      type { type }
      after(:build) do |lt|
        stripe_db_subscription = build(:stripe_db_subscription)
        lt.abstract_session = stripe_db_subscription.stripe_plan
      end
    end
  end

  # Service Subscriptions
  factory :purchased_service_subscription_log_transaction, parent: :log_transaction do
    type { 'purchased_service_subscription' }
    association :payment_transaction, factory: :real_stripe_transaction
    after(:build) do |lt|
      stripe_db_subscription = build(:stripe_service_subscription)
      lt.abstract_session = stripe_db_subscription.stripe_plan
    end
  end

  factory :aa_stub_transaction_logs, parent: :log_transaction
end
