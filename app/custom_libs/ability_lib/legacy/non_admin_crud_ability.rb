# frozen_string_literal: true

module AbilityLib
  module Legacy
    class NonAdminCrudAbility < AbilityLib::Legacy::Base
      def service_admin_abilities
        @service_admin_abilities ||= {
          read: [Recording, Organization, Session, User]
        }
      end

      def initialize(user)
        super user

        can :read, Channel do |channel|
          cache_key = "read/#{channel.cache_key}/#{user.try(:cache_key)}"
          Rails.cache.fetch(cache_key) do
            lambda do
              return true if channel.organizer == user
              return true if user&.presenter && channel.channel_invited_presenterships.where.not(status: :rejected).exists?(presenter_id: user.presenter_id)

              channel.approved? && !channel.fake? && !channel.organizer.fake? && !channel.draft? && !channel.rejected? && !channel.archived?
            end.call
          end
        end

        can :read, Recording do |recording|
          cache_key = "read/#{recording.cache_key}/#{recording.try(:cache_key)}"
          Rails.cache.fetch(cache_key) do
            lambda do
              return true if recording.done? && recording.published? && !recording.deleted_at
            end.call
          end
        end

        can :set_current, Organization do |organization|
          organization.user == user || user.organizations.exists?(id: organization.id)
        end

        can :read, Organization do |organization|
          lambda do
            return true if organization.user == user

            !organization.user.fake?
          end.call
        end

        can :create_company, User do
          user && user.organization.blank?
        end

        can :contact, User do |other_user|
          user.present? && user != other_user && !other_user.deleted?
        end

        can :have_in_wishlist, Session do |session|
          user_cache_key = user.try(:cache_key) # could be not logged in/nil
          Rails.cache.fetch("ability/have_in_wishlist/#{session.cache_key}/#{user_cache_key}") do
            lambda do
              return false if session.status.to_s == Session::Statuses::REQUESTED_FREE_SESSION_REJECTED

              # display it in UI as if it is possible
              return true if user.blank?

              # allowed even for users without confirmed emails
              # session.channel.organization != user.organization
              # TODO - prevent team members too?
              session.organizer != user
            end.call
          end
        end

        can :read, Session do |session|
          ::CanReadSession.new(user, session).can?
        end

        can :read, User do |_user|
          !_user.deleted?
        end

        can :request_session, Channel do |channel|
          # TODO: - prevent team members from requesting sessions?
          user.present? && !channel.archived? && channel.status != Channel::Statuses::REJECTED && channel.organizer != user
        end

        can :request_another_time, Session do |session|
          # TODO: - prevent team members from requesting sessions?
          # TODO - update config/initializers/rack-attack.rb ?

          user.present? && !session.finished? && !session.cancelled? && user != session.organizer
        end

        initialize_signed_in_abilities(user) if user.present?
      end

      def initialize_signed_in_abilities(user)
        can :be_notified_about_1st_published_session, Channel do |channel|
          Rails.cache.fetch("be_notified_about_1st_published_session/#{user.cache_key}/#{channel.id}") do
            lambda do
              return false if user.organization.present? && user.organization == channel.organization
              return false if user.presenter.present? && user.presenter == channel.presenter

              channel.sessions.blank? && UpcomingChannelNotificationMembership.where(channel: channel,
                                                                                     user: user).blank?
            end.call
          end
        end

        can :reimburse_refund, PendingRefund do |pending_refund|
          lambda do
            return false unless pending_refund.user == user

            session = pending_refund.abstract_session

            # because cancelled sessions doesn't have rooms
            session.cancelled? || !session.room_members.where(joined: true).exists?(abstract_user: user)
          end.call
        end

        # no need in caching - rarely executed(only when Review modal window is displayed after clicking *Add review*)
        can :create_or_update_review_comment, Session do |session|
          lambda do
            return false unless session.finished?
            return false if user.participant.blank?

            not_involved_participant = !session.has_immersive_participant?(user.participant_id)
            if not_involved_participant
              return false
            end

            rated_any_criteria = Rate.exists?(rater_id: user.id, rateable_id: session.id)
            return false unless rated_any_criteria

            true
          end.call
        end

        can :toggle_remind_me_session, Session do |session|
          session.organizer != user && session.upcoming? && !session.in_progress? && !session.running?
        end

        can :change_password, User do
          user.encrypted_password_was.present?
        end

        can :create_1st_channel, User do
          # TODO: add presenter members too?

          # cache key is invalidated via channel => presenter => user hierarchy of :touch-ing
          Rails.cache.fetch("create_1st_channel/#{user.cache_key}") do
            user.organization.blank? || user.channels.joins(:cover).count.zero?
          end
        end

        can :become_a_creator, User do
          # no channels or has 1 channel and it's autosaved(draft) from step2 and user didn't submit step 3
          user.channels.count.zero? || (user.channels.draft.count == 1 && user.channels.count == 1)
        end

        can :apply_as_participant, User do
          !user.has_payment_info?
        end

        can :follow, User do |another_user|
          user != another_user
        end

        can :follow, Organization do |_organization|
          user.present?
        end

        can :subscribe, Channel do |channel|
          user != channel.organizer
        end

        can :follow, Channel do |_channel|
          user.present?
        end

        can :like, Channel do |channel|
          !channel.archived? && channel.approved? && channel.listed? && channel.organizer != user
        end

        can :move_between_channels, Session do |session|
          user_cache_key = user.try(:cache_key) # could be not logged in/nil

          Rails.cache.fetch("ability/move_between_channels/#{session.cache_key}/#{user_cache_key}") do
            lambda do
              channel = session.channel
              return true if session.presenter_id == user.presenter_id
              return true if channel.organizer == user
              return true if channel.organization&.organization_memberships_active&.exists?(role: 'administrator', user_id: user.id)
              return true if user.presenter && channel.channel_invited_presenterships.exists?(
                presenter_id: user.presenter.id, status: 'accepted'
              )

              false
            end.call
          end
        end

        can :be_added_to_waiting_list_as_non_free_trial_immersive_method, Session do |session|
          !session.started? && Rails.cache.fetch("be_added_to_waiting_list_as_non_free_trial_immersive_method/#{session.cache_key}/#{user.cache_key}") do
            if session.private? || session.status.to_s == Session::Statuses::REQUESTED_FREE_SESSION_REJECTED || !session.immersive_delivery_method? ||
               session.cancelled? || (user.presenter.present? && (user.presenter.co_presenter?(session) || user.presenter.primary_presenter?(session))) ||
               session.has_immersive_participant?(user.participant_id) || session.livestreamers.where(participant: user.participant).present?
              false
            else
              session.immersive_participants.count >= session.max_number_of_immersive_participants
            end
          end
        end

        # NOTE: - if this permission changes do not forget to update SessionPublishReminder
        can :publish, Session do |session|
          lambda do
            return false if session.published? || session.finished?

            return false if session.status.to_s == Session::Statuses::REQUESTED_FREE_SESSION_PENDING \
                            || session.status.to_s == Session::Statuses::REQUESTED_FREE_SESSION_REJECTED

            channel = session.channel

            return false if channel.archived?

            return true if user.presenter && channel.channel_invited_presenterships.exists?(
              presenter_id: user.presenter.id, status: 'accepted'
            )
            return true if user.presenter && channel.organization.organization_memberships_active.exists?(user_id: user.id)

            if session.presenter_id == user.presenter_id
              # skipping this condition, all fine
            elsif channel.presenter_id.present?
              return false if channel.presenter_id != user.presenter_id
            elsif channel.organization.user != user
              return false
            end

            true
            # if session.private?
            #   true
            # else
            #   channel.listed?
            # end
          end.call
        end

        can :change_donations_amount_hidden_at, Session do |session|
          lambda do
            return true if session.organizer == user

            channel = session.channel
            if channel.organization.present? && channel.organization.user == user
              return true
            end

            false
          end.call
        end
      end
    end
  end
end
