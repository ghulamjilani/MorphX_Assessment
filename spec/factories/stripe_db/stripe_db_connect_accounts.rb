# frozen_string_literal: true

FactoryBot.define do
  factory :stripe_db_connect_account, class: 'StripeDb::ConnectAccount' do
    association :user
    account_id { 'dummy' }
  end
  factory :aa_stub_connect_accounts, parent: :stripe_db_connect_account
end
