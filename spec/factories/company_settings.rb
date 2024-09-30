# frozen_string_literal: true
FactoryBot.define do
  factory :company_setting do
    association :organization, factory: :organization
    logo_channel_link { true }
  end
  factory :aa_stub_company_settings, parent: :company_setting
end
