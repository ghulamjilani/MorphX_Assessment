# frozen_string_literal: true

FactoryBot.define do
  factory :plutus_debit_amount, class: 'Plutus::DebitAmount' do
    type { Plutus::DebitAmount }
    association :account, factory: :plutus_account
    association :entry, factory: :plutus_entry
    amount { 10 }
  end

  factory :aa_stub_plutus_debit_amounts, parent: :plutus_debit_amount
end
