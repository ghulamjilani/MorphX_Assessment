# frozen_string_literal: true

json.id                         feature_history_usage.id
json.feature_usage_id           feature_history_usage.feature_usage_id
json.model_id                   feature_history_usage.model_id
json.model_type                 feature_history_usage.model_type
json.action_name                feature_history_usage.action_name
json.usage_bytes                feature_history_usage.usage_bytes
json.created_at                 feature_history_usage.created_at.utc.to_fs(:rfc3339)
