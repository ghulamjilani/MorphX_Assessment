# frozen_string_literal: true

FactoryBot.define do
  factory :stripe_db_coupons, class: 'StripeDb::Coupon' do
    target_type { 'Session' }
  end
  factory :aa_stub_stripe_coupons, parent: :stripe_db_coupons
  factory :aa_stub_coupons, parent: :stripe_db_coupons
end
