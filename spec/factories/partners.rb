# frozen_string_literal: true
FactoryBot.define do
  factory :partner do
    association :category, factory: :channel_category
    title { 'test' }
    rid { 'test' }
    hosts { ['hosts'] }
  end

  factory :aa_stub_partners, parent: :partner
end
