# frozen_string_literal: true
FactoryBot.define do
  factory :company_feature_parameter do
    association :plan_feature, factory: :plan_feature
    association :subscription, factory: :stripe_service_subscription
    value { '20' }
  end
  factory :aa_stub_company_feature_parameters, parent: :company_feature_parameter
end
