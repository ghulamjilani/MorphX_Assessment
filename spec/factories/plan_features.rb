# frozen_string_literal: true
FactoryBot.define do
  factory :plan_feature do
    code { PlanFeature::CODES.sample }
    parameter_type { PlanFeature::TYPES.sample }
    name { Forgery(:name).first_name }
    description { Forgery(:lorem_ipsum).words(3) }
  end
  PlanFeature::CODES.each do |code|
    factory :"#{code}_plan_feature", parent: :plan_feature do
      code { code }
    end
  end
  factory :aa_stub_plan_features, parent: :plan_feature
end
