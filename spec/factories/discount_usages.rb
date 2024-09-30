# frozen_string_literal: true
FactoryBot.define do
  factory :discount_usage do
    user
    discount
  end
  factory :aa_stub_discount_usages, parent: :discount_usage
end
