# frozen_string_literal: true

module AbilityLib
  class ChannelAbility < AbilityLib::Base
    def service_admin_abilities
      @service_admin_abilities ||= {
        read: [Channel]
      }
    end

    def load_permissions
      can :read, Channel do |channel|
        cache_key = "read/#{channel.cache_key}/#{user.try(:cache_key)}"
        Rails.cache.fetch(cache_key) do
          lambda do
            return false if channel.archived?
            return false unless channel.organization.active_subscription_or_split_revenue?
            return true if channel.organizer == user
            return false unless channel.approved?
            return true if user.persisted? && user.presenter && channel.channel_invited_presenterships.where.not(status: :rejected).exists?(presenter_id: user.presenter_id)

            if Rails.application.credentials.global[:enterprise]
              return user.has_channel_credential?(channel, :view_content)
            end

            !channel.is_fake?
          end.call
        end
      end

      can :share, Channel do |channel|
        # NOTE: seems like listed status is not important here
        !channel.archived? && channel.approved?
      end

      return unless user.persisted?

      can :email_share, Channel do |channel|
        # seems like listed status is not important here
        # you may take rate limiting into account to avoid spamming #later
        can?(:share, channel)
      end

      # FOR SUBSCRIBERS
      can :have_trial, Channel do |channel|
        lambda do
          return false unless channel.subscription

          !::StripeDb::Subscription.exists?(user: user, stripe_plan: channel.subscription.plans)
        end.call
      end

      can :accept_or_reject_invitation, Channel do |channel|
        user_cache_key = user.try(:cache_key) # could be not logged in/nil
        Rails.cache.fetch("ability/accept_or_reject_invitation/#{channel.cache_key}/#{user_cache_key}") do
          lambda do
            return false if channel.organizer == user
            return false if user.presenter_id.blank?

            channel.channel_invited_presenterships.pending.exists?(presenter_id: user.presenter_id)
          end.call
        end
      end

      can :create_post, Channel do |channel|
        lambda do
          return false unless !channel.archived? && channel.approved?

          user.has_channel_credential?(channel, :manage_blog_post)
        end.call
      end

      can :edit, Channel do |channel|
        lambda do
          return false if channel.archived?

          user.has_channel_credential?(channel, :edit_channel)
        end.call
      end

      can :submit_for_review, Channel do |channel|
        channel.draft? && !channel.approved? && can?(:edit, channel)
      end

      can :list, Channel do |channel|
        !channel.listed? && channel.approved? && can?(:edit, channel)
      end

      can :unlist, Channel do |channel|
        raise ArgumentError unless channel.persisted?

        channel.listed? && channel.approved? && can?(:edit, channel)
      end

      can :archive, Channel do |channel|
        lambda do
          return false if channel.archived?

          user.has_organization_credential?(channel.organization, :archive_channel)
        end.call
      end

      can :manage_opt_in_modals, Channel do |channel|
        channel.organization.organizer == user
      end

      can :create_session, Channel do |channel|
        lambda do
          return false unless channel.approved? && !channel.archived?

          user.has_channel_credential?(channel, :create_session)
        end.call
      end

      can :upload_recording, Channel do |channel|
        lambda do
          return false if channel.archived?

          user.has_channel_credential?(channel, :create_recording)
        end.call
      end

      can :edit_recording, Channel do |channel|
        lambda do
          return false if channel.archived?

          user.has_channel_credential?(channel, :edit_recording)
        end.call
      end

      can :transcode_recording, Channel do |channel|
        lambda do
          return false if channel.archived?

          user.has_channel_credential?(channel, :transcode_recording)
        end.call
      end

      can :delete_recording, Channel do |channel|
        lambda do
          return false if channel.archived?

          user.has_channel_credential?(channel, :delete_recording)
        end.call
      end

      can :edit_replay, Channel do |channel|
        lambda do
          return false if channel.archived?

          user.has_channel_credential?(channel, :edit_replay)
        end.call
      end

      can :transcode_replay, Channel do |channel|
        lambda do
          return false if channel.archived?

          user.has_channel_credential?(channel, :transcode_replay)
        end.call
      end

      can :delete_replay, Channel do |channel|
        lambda do
          return false if channel.archived?

          user.has_channel_credential?(channel, :delete_replay)
        end.call
      end

      can :manage_documents, Channel do |channel|
        lambda do
          return false if channel.archived?

          user.has_channel_credential?(channel, :manage_documents)
        end.call
      end

      can :add_documents, Channel do |channel|
        lambda do
          return false unless user.persisted?
          return false if channel.archived?

          (channel.organization&.split_revenue? ||
            ::StripeDb::ServiceSubscription.exists?(user: channel.organization.user, service_status: %i[active trial pending_deactivation grace])) &&
            user.has_channel_credential?(channel, :manage_documents)
        end.call
      end

      can :manage_blog_post, Channel do |channel|
        lambda do
          return false if channel.archived?

          user.has_channel_credential?(channel, :manage_blog_post)
        end.call
      end

      can :request_session, Channel do |channel|
        # TODO: - prevent team members from requesting sessions?
        !channel.archived? && channel.status != Channel::Statuses::REJECTED && channel.organizer != user
      end

      can :be_notified_about_1st_published_session, Channel do |channel|
        Rails.cache.fetch("be_notified_about_1st_published_session/#{user.cache_key}/#{channel.id}") do
          lambda do
            return false if user.organization.present? && user.organization == channel.organization
            return false if user.presenter.present? && user.presenter == channel.presenter

            channel.sessions.blank? && UpcomingChannelNotificationMembership.where(channel: channel, user: user).blank?
          end.call
        end
      end

      can :subscribe, Channel do |channel|
        user != channel.organizer
      end

      can :follow, Channel do |_channel|
        user.persisted?
      end

      can :like, Channel do |channel|
        !channel.archived? && channel.approved? && channel.listed? && channel.organizer != user
      end

      can :create_session_by_business_plan, Channel do |channel|
        organization = channel.organization
        # check service subscription
        organization&.split_revenue? || ::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                                                service_status: %i[active trial pending_deactivation grace])
      end

      can :edit_session_by_business_plan, Channel do |channel|
        organization = channel.organization
        organization&.split_revenue? || ::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                                                service_status: %i[active trial pending_deactivation grace])
      end

      can :clone_session_by_business_plan, Channel do |channel|
        organization = channel.organization
        organization&.split_revenue? || ::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                                                service_status: %i[active trial pending_deactivation grace])
      end

      can :cancel_session_by_business_plan, Channel do |channel|
        organization = channel.organization
        organization&.split_revenue? || ::StripeDb::ServiceSubscription.exists?(user: organization.user,
                                                                                service_status: %i[active pending_deactivation trial trial_suspended grace suspended])
      end

      can :upload_videos_by_business_plan, Channel do |channel|
        channel.organization&.split_revenue? || ::StripeDb::ServiceSubscription.exists?(
          user: channel.organization.user, service_status: %i[active pending_deactivation trial grace]
        )
      end

      can :transcode_videos_by_business_plan, Channel do |channel|
        channel.organization&.split_revenue? || ::StripeDb::ServiceSubscription.exists?(
          user: channel.organization.user, service_status: %i[active pending_deactivation trial grace]
        )
      end

      can :read_im_conversation, Channel do |channel|
        Rails.cache.fetch("channel_ability/read_im_conversation/#{channel.cache_key}/#{user.cache_key}", expires_in: 1.hour) do
          lambda do
            return false unless user.persisted?
            return false unless Rails.application.credentials.dig(:global, :instant_messaging, :enabled)
            return false unless Rails.application.credentials.dig(:global, :instant_messaging, :conversations, :channels, :enabled)
            return false unless channel.im_conversation_enabled?
            return false unless channel.organization.active_subscription_or_split_revenue?
            return true if user.has_channel_credential?(channel, %i[participate_channel_conversation moderate_channel_conversation])
            return true if channel.free_subscriptions.in_action.with_features(:im_channel_conversation).exists?(user: user)

            ::StripeDb::Subscription.joins(:channel_subscription, :stripe_plan).exists?(
              user: user,
              status: %i[active trialing],
              subscriptions: { channel_id: channel.id },
              stripe_plans: { im_channel_conversation: true }
            )
          end.call
        end
      end

      can :create_im_message, Channel do |channel|
        lambda do
          return false unless user.persisted?
          return false if channel.im_conversation_participants.banned.exists?(abstract_user: user)

          can?(:read_im_conversation, channel)
        end.call
      end

      can :moderate_im_conversation, Channel do |channel|
        Rails.cache.fetch("channel_ability/moderate_im_conversation/#{channel.id}/#{user.cache_key}") do
          lambda do
            return false unless user.persisted?
            return false unless Rails.application.credentials.dig(:global, :instant_messaging, :enabled)
            return false unless Rails.application.credentials.dig(:global, :instant_messaging, :conversations, :channels, :enabled)
            return false unless channel.im_conversation_enabled?

            user.has_channel_credential?(channel, %i[moderate_channel_conversation])
          end.call
        end
      end

      can :view_revenue_report, Channel do |channel|
        Rails.cache.fetch("channel_ability/view_revenue_report/#{channel.id}/#{user.cache_key}") do
          lambda do
            return false unless user.persisted?

            user.has_channel_credential?(channel, %i[view_revenue_report])
          end.call
        end
      end

      can :manage_partner_subscriptions, Channel do |channel|
        lambda do
          return false unless user.current_organization.enable_free_subscriptions?
          return false unless user.current_organization_id != channel.organization_id

          user.has_channel_credential?(channel, :manage_channel_partner_subscriptions)
        end
      end
    end
  end
end
