# frozen_string_literal: true

json.extract! plan_package, :id, :name, :custom, :active, :recommended, :description, :position
json.platform_split_revenue_percent(100 - (plan_package.feature_parameters.by_code(:split_revenue_percent).first&.value.to_i || 70))
json.owner_split_revenue_percent(plan_package.feature_parameters.by_code(:split_revenue_percent).first&.value.to_i || 70)
json.plans do
  json.array! plan_package.plans do |plan|
    json.partial! 'api/v1/public/service_plans/plan', plan: plan

    json.money_currency do
      json.partial! 'api/v1/public/money/currencies/currency', currency: plan.money_currency
    end
  end
end
json.features do
  json.array! plan_package.feature_parameters do |feature_parameter|
    json.code feature_parameter.plan_feature.code
    json.value feature_parameter.value
    json.validation_regexp feature_parameter.plan_feature.validation_regexp
    json.parameter_type feature_parameter.plan_feature.parameter_type
  end
end
