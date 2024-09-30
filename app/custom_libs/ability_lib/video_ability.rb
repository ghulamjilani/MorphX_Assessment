# frozen_string_literal: true

module AbilityLib
  class VideoAbility < AbilityLib::Base
    def service_admin_abilities
      @service_admin_abilities ||= {
        see_video_as_paid_member: [Video],
        see_full_version_video: [Video]
      }
    end

    def load_permissions
      can :have_in_wishlist, Video do |video|
        video.organizer != user
      end

      can :read, Video do |video|
        video.channel.organization.active_subscription_or_split_revenue?
      end

      can :see_full_version_video, Video do |video|
        lambda do
          session = video.session
          return false unless video
          return false unless session.recorded_delivery_method?
          return false if Rails.application.credentials.global[:enterprise] && !user.has_channel_credential?(
            session.channel, :view_content
          )
          return true if session.organizer == user

          if video.only_subscription
            return false unless user.persisted?
            return false if video.only_ppv && !session.recorded_members.exists?(participant_id: user.participant_id)
            return true if session.channel.free_subscriptions.in_action.with_features(:replays).exists?(user: user)

            return ::StripeDb::Subscription.joins(:channel_subscription).exists?(
              user: user, status: %i[active trialing], subscriptions: { channel_id: session.channel.id }
            )
          end
          return true if session.recorded_purchase_price&.zero?
          return false unless user.persisted?
          return false if video.only_ppv && !session.recorded_members.exists?(participant_id: user.participant_id)
          return true if session.recorded_members.exists?(participant_id: user.participant_id)
          return true if session.channel.subscription && ::StripeDb::Subscription.joins(:stripe_plan).exists?(
            status: %i[active trialing], user: user, stripe_plan: session.channel.subscription.plans, stripe_plans: { im_replays: true }
          )

          session.channel.free_subscriptions.in_action.with_features(:replays).exists?(user: user)
        end.call
      end

      can :see_video_as_paid_member, Video do |video|
        lambda do
          return false if !video.try(:session) || video.channel.blank?
          return false unless user.persisted?

          return true if video.session.recorded_members.where(participant_id: user.participant_id).present?
          return true if video.channel.subscription && ::StripeDb::Subscription.joins(:stripe_plan).exists?(
            status: %i[active trialing], user: user, stripe_plan: video.channel.subscription.plans, stripe_plans: { im_replays: true }
          )

          video.channel.free_subscriptions.in_action.with_features(:replays).exists?(user: user)
        end.call
      end

      can :share, Video do |video|
        # you may take rate limiting into account to avoid spamming #later
        video.published? && video.session.published?
      end

      can :email_share, Video do |video|
        # you may take rate limiting into account to avoid spamming #later
        user.persisted? && can?(:share, video)
      end

      can :rate, Video do |video|
        can?(:see_full_version_video, video)
      end

      can :track_view, Video do |video|
        can?(:see_full_version_video, video)
      end
    end
  end
end
