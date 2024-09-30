# frozen_string_literal: true
FactoryBot.define do
  factory :pending_refund do
    association :payment_transaction, factory: :real_stripe_transaction
    user
  end
end
