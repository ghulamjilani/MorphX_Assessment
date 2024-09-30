# frozen_string_literal: true
class FeatureParameter < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  belongs_to :plan_feature
  belongs_to :plan_package

  validates :value, presence: true

  scope :by_code, ->(code) { joins(:plan_feature).where(plan_features: { code: code }) }
  scope :sessions_parameters, -> { joins(:plan_feature).where(plan_features: { code: ::PlanFeature::SESSION_CODES }) }

  def as_json(options)
    hash = {
      code: plan_feature.code,
      parameter_type: plan_feature.parameter_type,
      validation_regexp: plan_feature.validation_regexp
    }
    super(options).merge(hash)
  end
end
