# frozen_string_literal: true
class FeatureUsage < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  belongs_to :plan_feature, optional: false
  belongs_to :organization, optional: false

  has_many :feature_history_usages, dependent: :destroy
end
