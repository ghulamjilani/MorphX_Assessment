# frozen_string_literal: true
FactoryBot.define do
  factory :feature_usage do
    plan_feature do
      code = PlanFeature::CODES.sample
      PlanFeature.find_by(code: code) || create(:plan_feature, code: code)
    end
    association :organization, factory: :organization
  end
  factory :aa_stub_feature_usages, parent: :feature_usage
end
