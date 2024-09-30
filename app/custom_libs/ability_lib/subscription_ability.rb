# frozen_string_literal: true

module AbilityLib
  class SubscriptionAbility < AbilityLib::Base
    def service_admin_abilities
      @service_admin_abilities ||= {}
    end

    def load_permissions
      return unless user.persisted?

      can :subscribe, Subscription do |subscription|
        subscription && subscription.user != user && lambda do
          return false if subscription.channel.free_subscriptions.in_action.exists?(user: user)

          subscription.enabled && subscription.plans.exists?(im_enabled: true) && cannot?(:unsubscribe, subscription)
        end.call
      end

      can :unsubscribe, Subscription do |subscription|
        subscription && subscription.user != user && lambda do
          ::StripeDb::Subscription.exists?(user: user, stripe_plan: subscription.plans, status: %i[active trialing])
        end.call
      end
    end
  end
end
