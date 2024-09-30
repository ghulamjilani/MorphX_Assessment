# frozen_string_literal: true
class FeatureHistoryUsage < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :model, polymorphic: true, optional: false
  belongs_to :feature_usage, optional: false
  has_one :plan_feature, through: :feature_usage

  after_create :apply_to_feature_usage

  delegate :id, to: :plan_feature, allow_nil: false, prefix: true

  def apply_to_feature_usage
    feature_usage.fact_usage_bytes += usage_bytes
    feature_usage.save
  end
end
