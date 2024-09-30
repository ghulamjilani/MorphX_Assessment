# frozen_string_literal: true

FactoryBot.define do
  factory :stripe_db_connect_bank_account, class: 'StripeDb::ConnectBankAccount' do
    association :connect_account, factory: :stripe_db_connect_account
  end
  factory :aa_stub_connect_bank_accounts, parent: :stripe_db_connect_bank_account
end
