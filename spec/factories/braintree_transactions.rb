# frozen_string_literal: true
FactoryBot.define do
  factory :braintree_transaction do
    user
    status { 'submitted_for_settlement' }
    type { 'immersive_access' }
    association :abstract_session, factory: :immersive_session
    amount { 100 }
  end

  factory :aa_stub_braintree_transactions, parent: :braintree_transaction
end
