# frozen_string_literal: true
FactoryBot.define do
  factory :issued_system_credit do
    association :participant, factory: :participant
    status { 'expired' }
    type { 'chosen_refund' }
    amount { 10 }
  end
  factory :aa_stub_issued_system_credits, parent: :issued_system_credit
end
