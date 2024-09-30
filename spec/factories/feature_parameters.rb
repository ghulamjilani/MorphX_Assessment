# frozen_string_literal: true
FactoryBot.define do
  factory :feature_parameter do
    association :plan_feature, factory: :plan_feature
    association :plan_package, factory: :plan_package
    value { '20' }
  end
  factory :aa_stub_feature_parameters, parent: :feature_parameter
end
