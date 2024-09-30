# frozen_string_literal: true

json.extract! subscription, :id, :status, :service_status, :created_at, :canceled_at, :current_period_end
json.plan do
  json.partial! 'api/v1/public/service_plans/plan', plan: subscription.stripe_plan
end
json.plan_package do
  if subscription.plan_package.present?
    json.extract! subscription.plan_package, :id, :custom, :description, :name
  else
    json.id           nil
    json.custom       nil
    json.description  nil
    json.name         nil
  end
end
json.features do
  json.array!(subscription.plan_package&.feature_parameters || []) do |feature_parameter|
    json.code feature_parameter.plan_feature.code
    json.value feature_parameter.value
    json.validation_regexp feature_parameter.plan_feature.validation_regexp
    json.parameter_type feature_parameter.plan_feature.parameter_type
  end
end
