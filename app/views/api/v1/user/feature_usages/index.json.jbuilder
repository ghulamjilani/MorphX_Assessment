# frozen_string_literal: true

envelope json do
  json.feature_usages do
    json.array! @feature_usages do |feature_usage|
      json.feature_usage do
        json.partial! 'feature_usage', feature_usage: feature_usage
      end
      json.plan_feature do
        json.partial! 'api/v1/user/plan_features/plan_feature', plan_feature: feature_usage.plan_feature
      end
    end
  end
end
