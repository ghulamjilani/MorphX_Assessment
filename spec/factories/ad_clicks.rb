# frozen_string_literal: true
FactoryBot.define do
  factory :ad_click do
    association :user, factory: :user
    association :ad_banner, factory: :ad_banner
  end

  factory :aa_stub_ad_clicks, parent: :ad_click
end
