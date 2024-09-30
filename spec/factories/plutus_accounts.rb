# frozen_string_literal: true

FactoryBot.define do
  factory :plutus_account, class: 'Plutus::Account' do
    type { Plutus::Asset }
    sequence(:name) { |n| "Name #{n}" }
    contra { false }
  end

  factory :aa_stub_plutus_accounts, parent: :plutus_account
end
