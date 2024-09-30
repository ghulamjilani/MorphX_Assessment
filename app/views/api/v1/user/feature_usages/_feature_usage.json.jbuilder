# frozen_string_literal: true

json.id                         feature_usage.id
json.plan_feature_id            feature_usage.plan_feature_id
json.organization_id            feature_usage.organization_id
json.allocated_usage_bytes      feature_usage.allocated_usage_bytes
json.fact_usage_bytes           feature_usage.fact_usage_bytes
json.created_at                 feature_usage.created_at.utc.to_fs(:rfc3339)
