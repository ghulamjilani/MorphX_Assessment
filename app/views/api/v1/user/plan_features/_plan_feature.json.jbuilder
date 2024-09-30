# frozen_string_literal: true

json.cache!(plan_feature, expires_in: 1.day) do
  json.id                         plan_feature.id
  json.code                       plan_feature.code
  json.description                plan_feature.description
  json.name                       plan_feature.name
  json.parameter_type             plan_feature.parameter_type
  json.reset_usage_counter        plan_feature.reset_usage_counter
end
