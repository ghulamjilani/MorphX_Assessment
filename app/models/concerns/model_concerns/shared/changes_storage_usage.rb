# frozen_string_literal: true

module ModelConcerns
  module Shared
    module ChangesStorageUsage
      extend ActiveSupport::Concern

      included do
        def change_storage_usage!(bytes_diff, params = {})
          plan_feature = if Rails.env.test?
                           PlanFeature.find_or_create_by(code: :storage)
                         else
                           PlanFeature.find_by!(code: :storage)
                         end
          feature_usage = FeatureUsage.find_or_create_by!(organization_id:, plan_feature:)
          params = {
            model: self,
            usage_bytes: bytes_diff,
            feature_usage:
          }.merge(params)
          FeatureHistoryUsage.create!(params)
        end
      end
    end
  end
end
