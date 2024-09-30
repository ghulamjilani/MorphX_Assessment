# frozen_string_literal: true
FactoryBot.define do
  factory :merchant_category do
    code { :ac_refrigeration_repair }
    name { 'A/C, Refrigeration Repair' }
    mcc { '7623' }
  end

  factory :aa_stub_merchant_categories, parent: :merchant_category
end
