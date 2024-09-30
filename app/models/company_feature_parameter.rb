# frozen_string_literal: true
class CompanyFeatureParameter < ActiveRecord::Base
  include ModelConcerns::ActiveModel::Extensions
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :plan_feature
  belongs_to :subscription, class_name: 'StripeDb::ServiceSubscription', foreign_key: :stripe_service_subscription_id
end
