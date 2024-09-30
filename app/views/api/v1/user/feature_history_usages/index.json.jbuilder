# frozen_string_literal: true

envelope json do
  json.feature_history_usages do
    json.array! @feature_history_usages do |feature_history_usage|
      json.feature_history_usage do
        json.partial! 'feature_history_usage', feature_history_usage: feature_history_usage
      end
      json.feature_usage do
        json.partial! 'api/v1/user/feature_usages/feature_usage', feature_usage: feature_history_usage.feature_usage
      end
      json.plan_feature do
        json.partial! 'api/v1/user/plan_features/plan_feature', plan_feature: feature_history_usage.feature_usage.plan_feature
      end
    end
  end
end
