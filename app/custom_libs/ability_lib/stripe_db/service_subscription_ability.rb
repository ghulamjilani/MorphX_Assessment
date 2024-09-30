# frozen_string_literal: true

module AbilityLib
  module StripeDb
    class ServiceSubscriptionAbility < AbilityLib::StripeDb::Base
      def service_admin_abilities
        @service_admin_abilities ||= {}
      end

      def load_permissions
        can :edit_by_business_plan, ::StripeDb::ServiceSubscription do |subscription|
          Rails.application.credentials.global.dig(:service_subscriptions, :enabled) &&
            subscription.user_id == user.id
        end

        can :cancel_service_subscription, ::StripeDb::ServiceSubscription do |subscription|
          user.present? && subscription.user == user && !subscription.canceled?
        end
      end
    end
  end
end
