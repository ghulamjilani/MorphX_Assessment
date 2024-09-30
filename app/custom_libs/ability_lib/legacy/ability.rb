# frozen_string_literal: true

module AbilityLib
  module Legacy
    class Ability < AbilityLib::Legacy::Base
      def service_admin_abilities
        @service_admin_abilities ||= {
          see_video_as_paid_member: [Video],
          see_recording: [Recording]
        }
      end

      def initialize(user)
        super user

        can :share, Session do |session|
          session.status.to_s != Session::Statuses::REQUESTED_FREE_SESSION_REJECTED && session.published?
        end

        can :view_livestream_as_guest, Session do |session|
          if user
            false
          else
            session.published? && session.livestream_free && !session.only_subscription &&
              session.age_restrictions.to_i.zero? && !session.private &&
              !session.finished? && !session.cancelled?
          end
        end

        can :view_free_livestream, Session do |session|
          !session.stopped? && session.upcoming? && !session.cancelled? && session.published? && !session.finished? &&
            session.livestream_free && session.age_restrictions.to_i.zero? && !session.private
        end

        initialize_share_abilities(user)

        return if user.nil?

        initialize_general_abilities(user)

        initialize_reminder_abilities(user)
      end

      private

      def initialize_video_ability(user)
        can :see_video_as_paid_member, Video do |video|
          if !video.try(:session) || user.nil?
            false
          elsif video.session.recorded_members.where(participant_id: user.participant_id).present? ||
                (video.session.channel.subscription && ::StripeDb::Subscription.joins(:stripe_plan).exists?(
                  status: %i[active trialing], user: user, stripe_plan: video.session.channel.subscription.plans, stripe_plans: { im_replays: true }
                ))
            true
          else
            video.channel.free_subscriptions.in_action.with_features(:replays).exists?(user: user)
          end
        end
      end

      def initialize_recording_ability(user)
        can :see_recording, Recording do |recording|
          # raise(ArgumentError, recording.inspect) unless recording.vid

          if recording.private
            if user.blank?
              false
            else
              recording.channel.organizer == user ||
                recording.recording_members.where(participant_id: user.participant_id).present?
            end
          elsif recording.free? || (user && recording.channel.organizer == user)
            true
          else
            recording.recording_members.where(participant_id: user.try(:participant_id)).present?
          end
        end
      end

      def initialize_general_abilities(user)
        can :manage_payouts, User do
          user.has_owned_channels?
        end

        can :view_major_content, User do
          user.birthdate.blank? ? false : (Time.zone.now - user.birthdate.to_time(:utc)) > 21.years
        end

        can :view_adult_content, User do
          user.birthdate.blank? ? false : (Time.zone.now - user.birthdate.to_time(:utc)) > 18.years
        end

        can :download_desktop, User do
          user.presenter.present?
        end

        # NOTE: user is signed_in/present
        send :can, :join_as_participant, Session do |session|
          cache_key = "join_as_participant/#{session.cache_key}/#{user.cache_key}"

          !session.stopped? && session.upcoming? && !session.cancelled? && Rails.cache.fetch(cache_key) do
            session.has_immersive_participant?(user.participant_id) && !session.room_members.banned.exists?(abstract_user: user)
          end
        end

        # NOTE: user is signed_in/present
        send :can, :join_as_presenter, Session do |model|
          cache_key = "join_as_presenter/#{model.cache_key}/#{user.cache_key}"

          !model.stopped? && model.upcoming? && !model.cancelled? && Rails.cache.fetch(cache_key) do
            user == model.organizer
          end
        end

        send :can, :obtain_participation_without_invite, Session do |model|
          cache_key = "obtain_participation_without_invite/#{model.cache_key}/#{user.cache_key}"

          !model.stopped? && model.upcoming? && !model.cancelled? && Rails.cache.fetch(cache_key) do
            ObtainImmersiveAccessToSession.new(model, user).could_be_obtained_and_not_pending_invitee?
          end
        end

        # NOTE: user is signed_in/present
        can :join_as_co_presenter, Session do |session|
          cache_key = "join_as_co_presenter/#{session.cache_key}/#{user.cache_key}"

          !session.stopped? && session.upcoming? && !session.cancelled? && Rails.cache.fetch(cache_key) do
            user.presenter.present? && user.presenter.co_presenter?(session)
          end
        end

        can :join_as_livestreamer, Session do |session|
          cache_key = "join_as_livestreamer/#{session.cache_key}/#{user.cache_key}"

          !session.stopped? && session.upcoming? && !session.cancelled? && Rails.cache.fetch(cache_key) do
            (user.participant.present? && session.livestream_participants.include?(user.participant)) || can?(
              :access_as_subscriber, session
            )
          end
        end

        can :participate, Session do |session|
          can?(:join_as_presenter,
               session) || can?(:join_as_co_presenter, session) || can?(:join_as_participant, session)
        end

        can :start_immersive, Session do |session|
          user && session.webrtcservice? && (
            (can?(:join_as_presenter, session) && session.room.open?) ||
            (can?(:participate, session) && session.room.autostart && session.running?)
          )
        end

        can :join_immersive, Session do |session|
          user && session.webrtcservice? && (
            can?(:start_immersive, session) ||
            (can?(:participate, session) && session.running?)
          )
        end
      end

      def initialize_share_abilities(user)
        can :share, Channel do |channel|
          # NOTE: seems like listed status is not important here
          !channel.archived? && channel.approved?
        end

        can :email_share, Channel do |channel|
          # seems like listed status is not important here
          # you may take rate limiting into account to avoid spamming #later
          user.present? && can?(:share, channel)
        end

        can :share, User do |other_user|
          !other_user.deleted?
        end

        can :email_share, User do |other_user|
          user.present? && can?(:share, other_user)
        end

        can :share, Session do |session|
          # you may take rate limiting into account to avoid spamming #later
          session.published?
        end

        can :email_share, Session do |session|
          # you may take rate limiting into account to avoid spamming #later
          user.present? && can?(:share, session)
        end

        can :share, Video do |video|
          # you may take rate limiting into account to avoid spamming #later
          video.published? && video.session.published?
        end

        can :email_share, Video do |video|
          # you may take rate limiting into account to avoid spamming #later
          user.present? && can?(:share, video)
        end

        can :share, Recording do |recording|
          # you may take rate limiting into account to avoid spamming #later
          recording.channel.approved?
        end

        can :email_share, Recording do |recording|
          user.present? && can?(:share, recording)
        end

        can :share, ::Blog::Post do |blog_post|
          blog_post.status_published?
        end

        can :email_share, ::Blog::Post do |blog_post|
          user.present? && can?(:share, blog_post)
        end
      end

      def initialize_reminder_abilities(user)
        # no need in caching(executed from sidekiq job)
        can :receive_session_start_reminders, Session do |session|
          if user.session_reminders.exists?(session_id: session.id) || (user.presenter.present? && (user.presenter.primary_presenter?(session) ||
            user.presenter.co_presenter?(session))) ||
             (user.presenter.present? && session.session_invited_immersive_co_presenterships.where(presenter: user.presenter).pending.present?)
            true
          elsif user.participant.present?
            session.has_immersive_participant?(user.participant_id) ||
              session.has_livestream_participant?(user.participant_id) ||
              session.session_invited_immersive_participantships.where(participant: user.participant).pending.present? ||
              session.session_invited_livestream_participantships.where(participant: user.participant).pending.present?
          else
            false
          end
        end
      end
    end
  end
end
