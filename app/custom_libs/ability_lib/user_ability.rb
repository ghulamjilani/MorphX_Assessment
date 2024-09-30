# frozen_string_literal: true

module AbilityLib
  class UserAbility < AbilityLib::Base
    def service_admin_abilities
      @service_admin_abilities ||= {
        read: [User]
      }
    end

    def load_permissions
      can :read, User do |_user|
        !_user.deleted?
      end

      can :share, User do |other_user|
        !other_user.deleted?
      end

      return unless @user.persisted?

      can :manage_payouts, User do
        @user.has_owned_channels?
      end

      can :view_major_content, User do
        @user.birthdate.blank? ? false : (Time.zone.now - @user.birthdate.to_time(:utc)) > 21.years
      end

      can :view_adult_content, User do
        @user.birthdate.blank? ? false : (Time.zone.now - @user.birthdate.to_time(:utc)) > 18.years
      end

      can :download_desktop, User do
        @user.presenter.present?
      end

      can :email_share, User do |other_user|
        can?(:share, other_user)
      end

      # FOR SERVICE SUBSCRIBERS
      can :have_trial_service_subscription, User do
        !::StripeDb::ServiceSubscription.where.not(trial_start: nil).exists?(user: @user)
      end

      can :subscribe_service_subscription, User do
        !::StripeDb::ServiceSubscription.exists?(user: @user,
                                                 service_status: %i[active trial trial_suspended grace suspended
                                                                    pending_deactivation])
      end

      can :subscribe_as_gift_for, User do |recipient, subscription|
        recipient && @user != recipient && subscription && subscription.user != recipient && lambda do
          subscription.enabled && subscription.plans.exists?(im_enabled: true) &&
            !::StripeDb::Subscription.exists?(user: recipient, stripe_plan: subscription.plans,
                                              status: %i[active trialing])
        end.call
      end

      can :create_company, User do
        @user.organization.blank?
      end

      can :contact, User do |other_user|
        @user != other_user && !other_user.deleted?
      end

      can :change_password, User do
        @user.encrypted_password_was.present?
      end

      can :create_1st_channel, User do
        # TODO: add presenter members too?

        # cache key is invalidated via channel => presenter => user hierarchy of :touch-ing
        Rails.cache.fetch("create_1st_channel/#{@user.cache_key}") do
          @user.organization.blank? || @user.channels.joins(:cover).count.zero?
        end
      end

      can :become_a_creator, User do
        # no channels or has 1 channel and it's autosaved(draft) from step2 and user didn't submit step 3
        @user.channels.count.zero? || (@user.channels.draft.count == 1 && @user.channels.count == 1)
      end

      can :apply_as_participant, User do
        !@user.has_payment_info?
      end

      can :follow, User do |another_user|
        @user != another_user
      end

      can :access_wizard_by_business_plan, User do
        !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
          @user&.service_subscription.present?
      end
    end
  end
end
