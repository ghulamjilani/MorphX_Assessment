# frozen_string_literal: true

module AbilityLib
  class OrganizationAbility < AbilityLib::Base
    def service_admin_abilities
      @service_admin_abilities ||= {
        read: [Organization],
        access: [Organization]
      }
    end

    def load_permissions
      can :access, Organization do |organization|
        Rails.cache.fetch("organization_ability/access/organization/#{organization.cache_key}/#{user.cache_key}") do
          lambda do
            return false unless user.persisted?
            return true if organization.user == user

            user.organization_memberships_active.exists?(organization_id: organization.id)
          end.call
        end
      end

      can :edit, Organization do |organization|
        organization.active_subscription_or_split_revenue? &&
          user.has_organization_credential?(organization, :manage_organization)
      end

      can :create_channel, Organization do |organization|
        organization.active_subscription_or_split_revenue? &&
          user.has_organization_credential?(organization, :create_channel)
      end

      can :edit_channels, Organization do |organization|
        user.has_any_organization_credential?(organization, :edit_channel)
      end

      can :multiroom_config, Organization do |organization|
        user.has_organization_credential?(organization, :multiroom_config)
      end

      can :create_session, Organization do |organization|
        organization.active_subscription_or_split_revenue? &&
          user.has_any_organization_credential?(organization, :create_session)
      end

      can :archive_channels, Organization do |organization|
        user.has_any_organization_credential?(organization, :archive_channel)
      end

      can :accept_or_reject_invitation, Organization do |organization|
        user_cache_key = user.try(:cache_key) # could be not logged in/nil
        user.persisted? && Rails.cache.fetch("organization_ability/accept_or_reject_invitation/#{organization.cache_key}/#{user_cache_key}") do
          lambda do
            user.organization_memberships_participants.pending.exists?(organization: organization)
          end.call
        end
      end

      can :create_blog_image, Organization do |organization|
        user.persisted? && Rails.cache.fetch("organization_ability/create_blog_image/#{organization.cache_key}/#{user.cache_key}") do
          user.has_any_organization_credential?(organization, %i[manage_blog_post moderate_blog_post])
        end
      end

      # Documents
      can :manage_documents, Organization do |organization|
        organization.active_subscription_or_split_revenue? &&
          user.has_any_organization_credential?(organization, :manage_documents)
      end

      # Recordings
      can :upload_recording, Organization do |organization|
        organization.active_subscription_or_split_revenue? &&
          user.has_any_organization_credential?(organization, :create_recording)
      end

      can :edit_recording, Organization do |organization|
        organization.active_subscription_or_split_revenue? &&
          user.has_any_organization_credential?(organization, :edit_recording)
      end

      can :transcode_recording, Organization do |organization|
        organization.active_subscription_or_split_revenue? &&
          user.has_any_organization_credential?(organization, :transcode_recording)
      end

      can :delete_recording, Organization do |organization|
        user.has_any_organization_credential?(organization, :delete_recording)
      end

      # Video
      can :edit_replay, Organization do |organization|
        organization.active_subscription_or_split_revenue? &&
          user.has_any_organization_credential?(organization, :edit_replay)
      end

      can :transcode_replay, Organization do |organization|
        organization.active_subscription_or_split_revenue? &&
          user.has_any_organization_credential?(organization, :transcode_replay)
      end

      can :delete_replay, Organization do |organization|
        user.has_any_organization_credential?(organization, :delete_replay)
      end

      # Products
      can :manage_product, Organization do |organization|
        organization.active_subscription_or_split_revenue? &&
          user.has_any_organization_credential?(organization, :manage_product)
      end

      # User Management
      can :manage_roles, Organization do |organization|
        if Rails.application.credentials.global.dig(:service_subscriptions, :enabled)
          subscription = organization.user.service_subscription
          user.has_organization_credential?(organization, :manage_roles) &&
            (organization.split_revenue_plan || (subscription &&
            (subscription.feature_parameters.by_code(:manage_creators).first&.value == 'true' ||
              subscription.feature_parameters.by_code(:manage_admins).first&.value == 'true')))
        else
          user.has_organization_credential?(organization, :manage_roles)
        end
      end

      can :manage_admin, Organization do |organization|
        user.has_organization_credential?(organization, :manage_admin)
      end

      can :manage_creator, Organization do |organization|
        user.has_organization_credential?(organization, :manage_creator)
      end

      can :manage_enterprise_member, Organization do |organization|
        user.has_organization_credential?(organization, :manage_enterprise_member)
      end

      can :manage_superadmin, Organization do |organization|
        organization.user == user
      end

      can :invite_members, Organization do |organization|
        can?(:manage_team, organization)
      end

      can :remove_members, Organization do |organization|
        can?(:manage_team, organization)
      end

      can :manage_team, Organization do |organization|
        if Rails.application.credentials.global.dig(:service_subscriptions, :enabled)
          subscription = organization.user.service_subscription
          can?(:access, organization) && (organization.split_revenue_plan || (subscription &&
            %w[active pending_deactivation trial trial_suspended grace].include?(subscription.service_status) &&
            (subscription.feature_parameters.by_code(:manage_creators).first&.value == 'true' ||
              subscription.feature_parameters.by_code(:manage_admins).first&.value == 'true'))) &&
            (can?(:manage_superadmin, organization) ||
              can?(:manage_admin, organization) ||
              can?(:manage_creator, organization) ||
              can?(:manage_enterprise_member, organization))
        else
          can?(:access, organization) &&
            (can?(:manage_superadmin, organization) ||
              can?(:manage_admin, organization) ||
              can?(:manage_creator, organization) ||
              can?(:manage_enterprise_member, organization))
        end
      end

      can :view_statistics, Organization do |organization|
        can?(:view_video_report, organization) ||
          can?(:view_user_report, organization) ||
          can?(:view_revenue_report, organization) ||
          can?(:view_billing_report, organization)
      end

      # Subscriptions
      can :manage_channel_subscription, Organization do |organization|
        (!Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
          (organization.active_subscription_or_split_revenue? &&
          (organization.split_revenue_plan || organization.service_subscription_feature_value(:channel_subscriptions) == 'true'))) &&
          user.has_any_organization_credential?(organization, :manage_channel_subscription)
      end

      can :manage_business_plan, Organization do |organization|
        user.has_any_organization_credential?(organization, :manage_business_plan)
      end

      # Payments
      can :refund, Organization do |organization|
        user.has_any_organization_credential?(organization, :refund)
      end

      can :manage_payment_method, Organization do |organization|
        user.has_any_organization_credential?(organization, :manage_payment_method)
      end

      # Reports
      can :view_user_report, Organization do |organization|
        user.has_any_organization_credential?(organization, :view_user_report)
      end

      can :view_video_report, Organization do |organization|
        user.has_any_organization_credential?(organization, :view_video_report)
      end

      # Mailing
      can :mail, Organization do |organization|
        user.has_any_organization_credential?(organization, :mailing)
      end

      # Money Report
      can :view_billing_report, Organization do |organization|
        user.has_any_organization_credential?(organization, :view_billing_report)
      end

      can :view_revenue_report, Organization do |organization|
        user.has_any_organization_credential?(organization, :view_revenue_report)
      end

      # View
      can :view_content, Organization do |organization|
        user.has_any_organization_credential?(organization, :view_content)
      end

      # Comments and reviews
      can :moderate_comments_and_reviews, Organization do |organization|
        user.has_any_organization_credential?(organization, :moderate_comments_and_reviews)
      end

      # Booking
      can :manage_booking, Organization do |organization|
        (!Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
          organization.active_subscription_or_split_revenue?) &&
          user.has_any_organization_credential?(organization, :manage_booking)
      end

      # Polls
      can :manage_polls, Organization do |organization|
        (!Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
          organization.active_subscription_or_split_revenue?) &&
          user.has_any_organization_credential?(organization, :manage_polls)
      end

      # Blog
      can :manage_blog_post, Organization do |organization|
        user.has_any_organization_credential?(organization, :manage_blog_post)
      end

      can :moderate_blog_post, Organization do |organization|
        user.has_any_organization_credential?(organization, :moderate_blog_post)
      end

      can :set_current, Organization do |organization|
        membership_types = [:participant]
        membership_types << :guest if Rails.application.credentials.backend.dig(:organization_membership, :guests, :enabled)
        organization.user == user ||
          (organization.active_subscription_or_split_revenue? && user.organization_memberships.active.exists?(membership_type: membership_types, organization_id: organization.id))
      end

      can :read, Organization do |organization|
        lambda do
          return false unless organization.active_subscription_or_split_revenue?
          return true if organization.user == user

          organization.persisted? && !organization.fake && !organization.user.fake?
        end.call
      end

      can :follow, Organization do |_organization|
        user.persisted?
      end

      can :monetize_content_by_business_plan, Organization do |organization|
        # only for users like Suze & Ricky and users with active subscription
        !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
          (organization.present? && Rails.cache.fetch(
            "organization_ability/monetize_content/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
          ) do
            organization&.split_revenue_plan || ::StripeDb::ServiceSubscription.exists?(user: organization.user, service_status: %i[trial active pending_deactivation grace])
          end)
      end

      can :create_interactive_stream_feature, Organization do |organization|
        !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
          (organization.present? && Rails.cache.fetch(
            "organization_ability/interactive_stream/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
          ) do
            organization&.split_revenue_plan || (::StripeDb::ServiceSubscription.exists?(user: organization.user, service_status: %i[active pending_deactivation trial grace]) &&
              organization.user.service_subscription&.plan_package&.is_interactive_stream?)
          end)
      end

      can :manage_blog_by_business_plan, Organization do |organization|
        !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
          (organization.present? && Rails.cache.fetch(
            "organization_ability/manage_blog/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
          ) do
            organization&.split_revenue_plan ||
              (::StripeDb::ServiceSubscription.exists?(user: organization.user, service_status: %i[active pending_deactivation trial grace]) &&
              organization.user.service_subscription&.plan_package&.is_blog_available?)
          end)
      end

      can :manage_multiroom_by_business_plan, Organization do |organization|
        !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
          (organization.present? && Rails.cache.fetch(
            "organization_ability/access_multiroom/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
          ) do
            organization&.split_revenue_plan ||
              (::StripeDb::ServiceSubscription.exists?(user: organization.user, service_status: %i[active pending_deactivation trial grace]) &&
              organization.user.service_subscription&.plan_package&.is_multi_room?)
          end)
      end

      can :access_multiroom_by_business_plan, Organization do |organization|
        organization.multiroom_enabled? && can?(:manage_multiroom_by_business_plan, organization)
      end

      can :access_products_by_business_plan, Organization do |organization|
        !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
          (organization.present? && Rails.cache.fetch(
            "organization_ability/access_products/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
          ) do
            organization&.split_revenue_plan ||
              (::StripeDb::ServiceSubscription.exists?(user: organization.user, service_status: %i[active trial pending_deactivation grace]) &&
              organization.user.service_subscription&.plan_package&.instream_shopping?)
          end)
      end

      can :create_channel_by_business_plan, Organization do |organization|
        !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
          organization&.split_revenue_plan ||
          Rails.cache.fetch(
            "organization_ability/create_channel_by_business_plan/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
          ) do
            ::StripeDb::ServiceSubscription.exists?(user: organization.user, service_status: %i[active pending_deactivation trial grace]) &&
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
            "organization_ability/invite_admins_by_business_plan/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
          ) do
            ::StripeDb::ServiceSubscription.exists?(user: organization.user, service_status: %i[active pending_deactivation trial grace]) &&
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
            "organization_ability/invite_creators_by_business_plan/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
          ) do
            ::StripeDb::ServiceSubscription.exists?(user: organization.user, service_status: %i[active pending_deactivation trial grace]) &&
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
            "organization_ability/invite_members_by_business_plan/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
          ) do
            ::StripeDb::ServiceSubscription.exists?(user: organization.user, service_status: %i[active pending_deactivation trial grace]) &&
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
          organization&.split_revenue_plan || ::StripeDb::ServiceSubscription.exists?(user: organization.user, service_status: %i[active trial pending_deactivation grace])
      end

      can :manage_creators_by_business_plan, Organization do |organization|
        !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
          organization&.split_revenue_plan ||
          Rails.cache.fetch(
            "organization_ability/manage_creators_by_business_plan/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
          ) do
            ::StripeDb::ServiceSubscription.exists?(user: organization.user, service_status: %i[active pending_deactivation trial grace]) &&
              organization.user.service_subscription&.plan_package&.manage_creators?
          end
      end

      can :manage_admins_by_business_plan, Organization do |organization|
        !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
          organization&.split_revenue_plan ||
          Rails.cache.fetch(
            "organization_ability/manage_admins_by_business_plan/#{organization&.id}/#{organization.try(:cache_key)}", expires_in: 24.hours
          ) do
            ::StripeDb::ServiceSubscription.exists?(user: organization.user, service_status: %i[active pending_deactivation trial grace]) &&
              organization.user.service_subscription&.plan_package&.manage_admins?
          end
      end

      can :manage_contacts_and_mailing_by_business_plan, Organization do |organization|
        !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
          organization&.split_revenue_plan ||
          ::StripeDb::ServiceSubscription.exists?(user: organization.user, service_status: %i[active trial trial_suspended pending_deactivation grace])
      end

      can :start_session, Organization do |organization|
        organization.user == user || (can?(:access, organization) &&
          Rails.cache.fetch("organization_ability/start_session/organization/#{organization.cache_key}/#{user.cache_key}") do
            user.credentials.where(organization_memberships: { organization_id: organization.id }).exists?(code: 'start_session')
          end)
      end
    end
  end
end
