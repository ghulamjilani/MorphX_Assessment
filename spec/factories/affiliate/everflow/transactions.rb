# frozen_string_literal: true
FactoryBot.define do
  factory :affiliate_everflow_transaction, class: 'Affiliate::Everflow::Transaction' do
    association :user
    transaction_id { SecureRandom.numeric(12) }
  end
  factory :aa_stub_affiliate_everflow_transactions, parent: :affiliate_everflow_transaction
end
