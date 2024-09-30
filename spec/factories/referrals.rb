# frozen_string_literal: true
FactoryBot.define do
  factory :referral do
    association :master_user, factory: :user
    association :referral_code, factory: :referral_code
    association :user, factory: :user
  end

  factory :aa_stub_referrals, parent: :referral
end
