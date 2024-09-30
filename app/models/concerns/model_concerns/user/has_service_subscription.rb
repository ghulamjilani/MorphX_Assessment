# frozen_string_literal: true

module ModelConcerns
  module User
    module HasServiceSubscription
      extend ActiveSupport::Concern

      included do
        has_many :service_subscriptions, class_name: 'StripeDb::ServiceSubscription', dependent: :destroy
      end

      def service_subscription
        @service_subscription ||= service_subscriptions.where.not(service_status: [:deactivated]).order(created_at: :desc).first
      end

      def service_subscription_feature_value(code)
        return nil unless service_subscription

        service_subscription.feature_value(code)
      end
    end
  end
end
