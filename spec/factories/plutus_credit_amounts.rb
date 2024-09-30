# frozen_string_literal: true

FactoryBot.define do
  factory :plutus_credit_amount, class: 'Plutus::CreditAmount' do
    type { Plutus::CreditAmount }
    association :account, factory: :plutus_account
    association :entry, factory: :plutus_entry
    amount { 10 }
  end

  factory :aa_stub_plutus_credit_amounts, parent: :plutus_credit_amount
end
