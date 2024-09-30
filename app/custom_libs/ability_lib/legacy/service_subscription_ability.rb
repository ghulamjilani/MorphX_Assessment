# frozen_string_literal: true

module AbilityLib
  module Legacy
    class ServiceSubscriptionAbility < AbilityLib::Legacy::Base
      def initialize(user)
        super user

        can :access_wizard_by_business_plan, User do
          !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
            user&.service_subscription.present?
        end

        can :edit_by_business_plan, ::StripeDb::ServiceSubscription do |subscription|
          Rails.application.credentials.global.dig(:service_subscriptions, :enabled) &&
            subscription.user_id == user.id
        end

        can :monetize_content_by_business_plan, Organization do |organization|
          # only for users like Suze & Ricky and users with active subscription
          !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
            (organization.present? && Rails.cache.fetch(
              "ability/monetize_content/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
            ) do
              organization&.split_revenue_plan || ::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                                                          service_status: %i[active trial pending_deactivation grace])
            end)
        end

        can :monetize_content_by_business_plan, Channel do |channel|
          can?(:monetize_content_by_business_plan, channel.organization)
        end

        can :monetize_content_by_business_plan, User do
          can?(:monetize_content_by_business_plan, user.current_organization)
        end

        can :create_interactive_stream_feature, Organization do |organization|
          !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
            (organization.present? && Rails.cache.fetch(
              "ability/interactive_stream/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
            ) do
              organization&.split_revenue_plan || (::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                                                           service_status: %i[active pending_deactivation trialing grace]) &&
                organization.user.service_subscription&.plan_package&.is_interactive_stream?)
            end)
        end

        can :manage_blog_by_business_plan, Organization do |organization|
          !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
            (organization.present? && Rails.cache.fetch(
              "ability/manage_blog/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
            ) do
              organization&.split_revenue_plan || (::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                                                           service_status: %i[active pending_deactivation trial grace]) &&
                organization.user.service_subscription&.plan_package&.is_blog_available?)
            end)
        end
        can :manage_blog_by_business_plan, User do
          can?(:manage_blog_by_business_plan, user.current_organization)
        end

        can :manage_multiroom_by_business_plan, Organization do |organization|
          !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
            (organization.present? && Rails.cache.fetch(
              "ability/access_multiroom/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
            ) do
              organization&.split_revenue_plan || (::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                                                           service_status: %i[active pending_deactivation trial grace]) &&
                organization.user.service_subscription&.plan_package&.is_multi_room?)
            end)
        end
        can :access_multiroom_by_business_plan, Organization do |organization|
          organization.multiroom_enabled? && can?(:manage_multiroom_by_business_plan, organization)
        end

        can :access_products_by_business_plan, Organization do |organization|
          !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
            (organization.present? && Rails.cache.fetch(
              "ability/access_products/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
            ) do
              organization&.split_revenue_plan || (::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                                                           service_status: %i[active pending_deactivation trial grace]) &&
                organization.user.service_subscription&.plan_package&.instream_shopping?)
            end)
        end

        can :access_products_by_business_plan, Channel do |channel|
          can?(:access_products_by_business_plan, channel.organization)
        end

        can :access_products_by_business_plan, User do
          can?(:access_products_by_business_plan, user.current_organization)
        end

        can :create_channel_by_business_plan, Organization do |organization|
          !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
            organization&.split_revenue_plan ||
            Rails.cache.fetch(
              "ability/create_channel_by_business_plan/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
            ) do
              ::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                      service_status: %i[active pending_deactivation trial grace]) &&
                lambda do
                  subscription = organization.user.service_subscription
                  max_channels_count = subscription&.plan_package ? subscription.plan_package.max_channels_count : 0
                  return true if max_channels_count == -1

                  organization.channels.not_archived.count < max_channels_count
                end.call
            end
        end

        can :invite_admins_by_business_plan, Organization do |organization|
          !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
            organization&.split_revenue_plan ||
            Rails.cache.fetch(
              "ability/invite_admins_by_business_plan/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
            ) do
              ::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                      service_status: %i[active pending_deactivation trial grace]) &&
                lambda do
                  subscription = organization.user.service_subscription
                  max_admins_count = subscription&.plan_package ? subscription.plan_package.max_admins_count : 0
                  return true if max_admins_count == -1

                  organization.organization_memberships_participants.admins.count.size < max_admins_count
                end.call
            end
        end

        can :invite_creators_by_business_plan, Organization do |organization|
          !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
            organization&.split_revenue_plan ||
            Rails.cache.fetch(
              "ability/invite_creators_by_business_plan/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
            ) do
              ::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                      service_status: %i[active pending_deactivation trial grace]) &&
                lambda do
                  subscription = organization.user.service_subscription
                  max_creators_count = subscription&.plan_package ? subscription.plan_package.max_creators_count : 0
                  return true if max_creators_count == -1

                  organization.organization_memberships_participants.creators.count.size < max_creators_count
                end.call
            end
        end

        can :invite_members_by_business_plan, Organization do |organization|
          !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
            organization&.split_revenue_plan ||
            Rails.cache.fetch(
              "ability/invite_members_by_business_plan/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
            ) do
              ::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                      service_status: %i[active pending_deactivation trial grace]) &&
                lambda do
                  subscription = organization.user.service_subscription
                  max_members_count = subscription&.plan_package ? subscription.plan_package.max_members_count : 0
                  return true if max_members_count == -1

                  organization.organization_memberships_participants.members.count.size < max_members_count
                end.call
            end
        end

        can :create_session_by_business_plan, Organization do |organization|
          # check service subscription
          !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
            organization&.split_revenue_plan || ::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                                                        service_status: %i[active pending_deactivation trial grace])
        end

        can :create_session_by_business_plan, Channel do |channel|
          # channel active and has subscription
          can?(:create_session_by_business_plan, channel.organization)
        end

        can :create_session_by_business_plan, User do
          can?(:create_session_by_business_plan, user.current_organization)

          # user.present? &&
          #   (!Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
          #     user.organization && (user.organization.split_revenue_plan ||
          #       ::StripeDb::ServiceSubscription.exists?(user: user, service_status: [:active, :trial, :grace]))) &&
          #   (user.has_invited_channels? || user.has_owned_channels? && user.channels.approved.not_archived.count > 0)
        end

        can :edit_session_by_business_plan, Channel do |channel|
          organization = channel.organization
          !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
            organization&.split_revenue_plan || ::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                                                        service_status: %i[active pending_deactivation trial grace])
        end

        can :clone_session_by_business_plan, Channel do |channel|
          organization = channel.organization
          !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
            organization&.split_revenue_plan || ::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                                                        service_status: %i[active pending_deactivation trial grace])
        end

        can :cancel_session_by_business_plan, Channel do |channel|
          organization = channel.organization
          !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
            organization&.split_revenue_plan || ::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                                                        service_status: %i[active pending_deactivation trial trial_suspended grace suspended])
        end

        can :upload_videos_by_business_plan, Channel do |channel|
          !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
            channel.organization&.split_revenue_plan || ::StripeDb::ServiceSubscription.exists?(
              user: channel.organization.user, service_status: %i[active pending_deactivation trial grace]
            )
        end

        can :transcode_videos_by_business_plan, Channel do |channel|
          !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
            channel.organization&.split_revenue_plan || ::StripeDb::ServiceSubscription.exists?(
              user: channel.organization.user, service_status: %i[active pending_deactivation trial grace]
            )
        end

        can :manage_creators_by_business_plan, Organization do |organization|
          !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
            organization&.split_revenue_plan ||
            Rails.cache.fetch(
              "ability/manage_creators_by_business_plan/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
            ) do
              ::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                      service_status: %i[active pending_deactivation trial grace]) &&
                organization.user.service_subscription&.plan_package&.manage_creators?
            end
        end

        can :manage_creators_by_business_plan, Channel do |channel|
          can?(:manage_creators_by_business_plan, channel.organization)
        end

        can :manage_contacts_and_mailing_by_business_plan, Organization do |organization|
          !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
            organization&.split_revenue_plan || ::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                                                        service_status: %i[active pending_deactivation trial grace])
        end

        can :manage_contacts_and_mailing_by_business_plan, User do
          can?(:manage_contacts_and_mailing_by_business_plan, user.current_organization)
        end
      end
    end
  end
end
