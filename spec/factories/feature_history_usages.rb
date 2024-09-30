# frozen_string_literal: true
FactoryBot.define do
  factory :feature_history_usage do
    association :feature_usage, factory: :feature_usage
    model { create(%i[video recording].sample) }
    usage_bytes { rand(9_999_999) }
    action_name { 'factory usage' }
  end
  factory :aa_stub_feature_history_usages, parent: :feature_history_usage
end
