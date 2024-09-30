# frozen_string_literal: true
FactoryBot.define do
  factory :system_credit_entry do
    participant
    amount { 7.12 }
    description { 'Purchase with system credit - Well-done: Cogibox T...' }
    commercial_document { FactoryBot.create(:immersive_session, immersive_access_cost: 7.12, duration: 15) }
    type { TransactionTypes::IMMERSIVE }
  end
end
