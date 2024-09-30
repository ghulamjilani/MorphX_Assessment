# frozen_string_literal: true
FactoryBot.define do
  factory :referral_code do
    user
    sequence(:code) { |n| "seq#{n}" }
  end

  factory :aa_stub_referral_codes, parent: :referral_code
end
