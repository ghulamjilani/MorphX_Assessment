# frozen_string_literal: true

module AbilityLib
  module Legacy
    class AccountingAbility < AbilityLib::Legacy::Base
      def service_admin_abilities
        @service_admin_abilities ||= {
          obtain_recorded_access_to_free_session: [Session],
          obtain_free_trial_immersive_access: [Session],
          obtain_free_trial_livestream_access: [Session],
          obtain_immersive_access_to_free_session: [Session],
          obtain_livestream_access_to_free_session: [Session],
          access_as_subscriber: [Session],
          access_replay_as_subscriber: [Session],
          take_for_free: [Recording]
        }
      end

      def initialize(user)
        super user

        can :purchase_immersive_access, Session do |session|
          user_cache_key = user.try(:cache_key) # could be not logged in/nil
          Rails.cache.fetch("ability/purchase_immersive_access/#{session.cache_key}/#{user_cache_key}") do
            lambda do
              participant_id = user.try(:participant_id)

              if user.present?
                # fixes #1097
                return false if PendingRefund.where(user: user, payment_transaction: session.payment_transactions).present?

                # invited co-presenter
                if user.presenter.present? && session.session_invited_immersive_co_presenterships.where(presenter: user.presenter).pending.present?
                  return true
                end
              end

              return false if user.present? && user.presenter.present? && user == session.organizer
              return false if session.finished? || !session.published? || session.cancelled? || !session.immersive_delivery_method? || session.immersive_free
              return false if session.immersive_purchase_price.zero?
              return false if user.present? && session.has_co_presenter?(user.try(:presenter_id))
              return false if user.present? && session.has_immersive_participant?(user.participant_id) # already bought
              return false if session.status.to_s == Session::Statuses::REQUESTED_FREE_SESSION_PENDING

              # NOTE: - from this line user is not a co-presenter for sure

              if session.private?
                if user.present? && session.session_invited_immersive_participantships.where(participant_id: user.participant_id).pending.present?
                  return true
                else
                  return false
                end
              end

              case session.immersive_type
              when Session::ImmersiveTypes::ONE_ON_ONE
                session.immersive_participants.count.zero?
              when Session::ImmersiveTypes::GROUP
                session.interactive_slots_available?
              end
            end.call
          end
        end

        can :purchase_immersive_access_with_system_credit, Session do |session, charge_amount|
          can?(:purchase_immersive_access, session) && user.system_credit_balance >= charge_amount
        end

        can :purchase_livestream_access, Session do |session|
          user_cache_key = user.try(:cache_key) # could be not logged in/nil
          Rails.cache.fetch("ability/purchase_livestream_access/#{session.cache_key}/#{user_cache_key}") do
            lambda do
              participant_id = user.try(:participant_id)

              return false if session.finished? || !session.published? || session.cancelled? || !session.livestream_delivery_method? || session.livestream_free
              return false if session.livestream_purchase_price.zero?
              return false if user.present? && user.presenter.present? && (user.presenter.co_presenter?(session) || user.presenter.primary_presenter?(session))

              # fixes #1097
              return false if user.present? && PendingRefund.where(user: user, payment_transaction: session.payment_transactions).present?

              invited_as_co_presenter = user.present? && user.presenter.present? && session.session_invited_immersive_co_presenterships.where(presenter: user.presenter).pending.present?
              return false if invited_as_co_presenter

              session.livestreamers.where(participant_id: participant_id).blank?
            end.call
          end
        end

        can :purchase_livestream_access_with_system_credit, Session do |session|
          can?(:purchase_livestream_access, session) && user.system_credit_balance >= session.livestream_purchase_price
        end

        # NOTE: - this ability check has to ignore whether VOD is already available or not(!)
        # because this is check additionally and separately
        can :purchase_recorded_access, Session do |session|
          user_cache_key = user.try(:cache_key) # could be not logged in/nil
          Rails.cache.fetch("ability/purchase_recorded_access/#{session.cache_key}/#{user_cache_key}") do
            lambda do
              return false if session.organizer == user
              return false if session.recorded_purchase_price.blank? || session.recorded_purchase_price.zero?

              participant_id = user.try(:participant_id)

              if !session.published? || session.cancelled? || !session.recorded_delivery_method?
                return false
              end

              return false if user.present? && PendingRefund.where(user: user,
                                                                   payment_transaction: session.payment_transactions).present?

              session.recorded_members.where(participant_id: participant_id).blank?
            end.call
          end
        end

        can :obtain_recorded_access_to_free_session, Session do |session|
          user_cache_key = user.try(:cache_key)
          !session.recorded_purchase_price.nil? && session.recorded_purchase_price.zero? && Rails.cache.fetch("ability/obtain_recorded_access_to_free_session/#{session.cache_key}/#{user_cache_key}") do
            lambda do
              return false if session.organizer == user

              participant_id = user.try(:participant_id)

              if !session.published? || session.cancelled? || !session.recorded_delivery_method?
                return false
              end

              return false if user.present? && PendingRefund.where(user: user,
                                                                   payment_transaction: session.payment_transactions).present?

              session.recorded_members.where(participant_id: participant_id).blank?
            end.call
          end
        end

        can :obtain_free_trial_immersive_access, Session do |session|
          user_cache_key = user.try(:cache_key)
          Rails.cache.fetch("ability/obtain_free_trial_immersive_access/#{session.cache_key}/#{session.channel.cache_key}/#{user_cache_key}") do
            lambda do
              return false if session.free_trial_for_first_time_participants == false
              return false if session.immersive_free_slots.nil? || session.immersive_free_slots.zero?
              return false if session.organizer == user
              return false unless session.published?
              return false if session.immersive_free
              return false if session.finished? || session.cancelled? || !session.immersive_delivery_method?

              participant_id = user.try(:participant_id)
              presenter_id   = user.try(:presenter_id)

              already_member = session.session_participations.where(participant_id: participant_id).present? || \
                               session.session_co_presenterships.where(presenter_id: presenter_id).present?
              return false if already_member

              invited_as_co_presenter = session.session_invited_immersive_co_presenterships.where(presenter_id: presenter_id).where.not(status: 'rejected').present?
              return false if invited_as_co_presenter

              return false if session.livestreamers.where(participant_id: participant_id).present?

              # fixes #1097
              return false if user.present? && PendingRefund.where(user: user,
                                                                   payment_transaction: session.payment_transactions).present?

              return false unless session.interactive_slots_available?

              return false if Session
                              .joins(:session_participations)
                              .where(session_participations: { session_id: session.id,
                                                               free_trial: true }).count >= session.immersive_free_slots

              Session
                .joins(:session_participations)
                .free_trial_for_first_time_participants
                .where(channel_id: session.channel_id)
                .where(session_participations: { participant_id: participant_id, free_trial: true }).blank? \
              && Session
                .joins(:livestreamers)
                .free_trial_for_first_time_participants
                .where(channel_id: session.channel_id)
                .where(livestreamers: { participant_id: participant_id, free_trial: true }).blank?
            end.call
          end
        end

        can :obtain_free_trial_livestream_access, Session do |session|
          user_cache_key = user.try(:cache_key)
          Rails.cache.fetch("ability/obtain_free_trial_livestream_access/#{session.cache_key}/#{session.channel.cache_key}/#{user_cache_key}") do
            lambda do
              return false if session.free_trial_for_first_time_participants == false
              return false if session.livestream_free_slots.nil? || session.livestream_free_slots.zero?
              return false if session.organizer == user
              return false if session.livestream_free
              return false unless session.published?
              return false if session.finished? || session.cancelled? || !session.livestream_delivery_method?

              participant_id = user.try(:participant_id)
              presenter_id   = user.try(:presenter_id)

              return false if session.livestreamers.where(participant_id: participant_id).present?
              return false if session.session_participations.where(participant_id: participant_id).present?
              return false if session.session_co_presenterships.where(presenter_id: presenter_id).present?

              invited_as_co_presenter = user.present? && user.presenter.present? && session.session_invited_immersive_co_presenterships.where(presenter: user.presenter).pending.present?
              return false if invited_as_co_presenter

              # fixes #1097
              return false if user.present? && PendingRefund.where(user: user,
                                                                   payment_transaction: session.payment_transactions).present?

              return false if Session
                              .joins(:livestreamers)
                              .where(livestreamers: { session_id: session.id,
                                                      free_trial: true }).count >= session.livestream_free_slots

              Session
                .joins(:livestreamers)
                .free_trial_for_first_time_participants
                .where(channel_id: session.channel_id)
                .where(livestreamers: { participant_id: participant_id, free_trial: true }).blank? \
              && Session
                .joins(:session_participations)
                .free_trial_for_first_time_participants
                .where(channel_id: session.channel_id)
                .where(session_participations: { participant_id: participant_id, free_trial: true }).blank?
            end.call
          end
        end

        can :obtain_immersive_access_to_free_session, Session do |session|
          user_cache_key = user.try(:cache_key)
          Rails.cache.fetch("ability/obtain_immersive_access_to_free_session/#{session.cache_key}/#{user_cache_key}") do
            lambda do
              return false if session.organizer == user
              return false unless session.published?
              return false if session.immersive_purchase_price.present? && !session.immersive_purchase_price.zero?
              return false if session.finished? || session.cancelled?

              invited_as_co_presenter = user.present? && user.presenter.present? && session.session_invited_immersive_co_presenterships.where(presenter: user.presenter).pending.present?
              return true if invited_as_co_presenter

              return false unless session.immersive_delivery_method?

              participant_id = user.try(:participant_id)
              presenter_id   = user.try(:presenter_id)

              return false if session.livestreamers.where(participant_id: participant_id).present?

              # fixes #1097
              return false if user.present? && PendingRefund.where(user: user,
                                                                   payment_transaction: session.payment_transactions).present?

              return false unless session.interactive_slots_available?

              # not already a member
              session.session_participations.where(participant_id: participant_id).blank? && \
                session.session_co_presenterships.where(presenter_id: presenter_id).blank?
            end.call
          end
        end

        can :obtain_livestream_access_to_free_session, Session do |session|
          user_cache_key = user.try(:cache_key)
          Rails.cache.fetch("ability/obtain_livestream_access_to_free_session/#{session.cache_key}/#{user_cache_key}") do
            lambda do
              return false if session.organizer == user
              return false if session.livestream_purchase_price.present? && !session.livestream_purchase_price.zero?
              return false unless session.published?
              return false if session.finished? || session.cancelled? || !session.livestream_delivery_method?

              participant_id = user.try(:participant_id)
              presenter_id   = user.try(:presenter_id)

              # not already a member
              return false if session.livestreamers.where(participant_id: participant_id).present?
              return false if session.session_participations.where(participant_id: participant_id).present?
              return false if session.session_co_presenterships.where(presenter_id: presenter_id).present?

              invited_as_co_presenter = user.present? && user.presenter.present? && session.session_invited_immersive_co_presenterships.where(presenter: user.presenter).pending.present?
              return false if invited_as_co_presenter

              # fixes #1097
              return false if user.present? && PendingRefund.where(user: user,
                                                                   payment_transaction: session.payment_transactions).present?

              session.livestreamers.where(participant_id: participant_id).blank?
            end.call
          end
        end

        # FOR SERVICE SUBSCRIBERS
        can :have_trial_service_subscription, User do
          user.present? && !::StripeDb::ServiceSubscription.exists?(user: user)
        end
        can :subscribe_service_subscription, User do
          user.present? && !::StripeDb::ServiceSubscription.exists?(user: user,
                                                                    service_status: %i[active trial trial_suspended
                                                                                       grace suspended pending_deactivation])
        end
        can :cancel_service_subscription, ::StripeDb::ServiceSubscription do |subscription|
          user.present? && subscription.user == user && !subscription.canceled?
        end

        # FOR SUBSCRIBERS
        can :have_trial, Channel do |channel|
          user.present? && lambda do
            return false unless channel.subscription

            !::StripeDb::Subscription.exists?(user: user, stripe_plan: channel.subscription.plans)
          end.call
        end

        can :access_as_subscriber, Session do |session|
          user.present? && lambda do
            # channel has no plans
            return false unless session.livestream_delivery_method?
            return false unless session.livestream_purchase_price.positive?
            return true if session.channel.free_subscriptions.in_action.exists?(user: user)
            return false unless session.channel.subscription

            ::StripeDb::Subscription.exists?(status: %i[active trialing], user: user,
                                             stripe_plan: session.channel.subscription.plans)
          end.call
        end

        can :access_replay_as_subscriber, Session do |session|
          user.present? && lambda do
            # channel has no plans
            return false unless session.recorded_delivery_method?
            return false unless session.recorded_purchase_price.positive?
            return true if session.channel.free_subscriptions.in_action.with_features(:replays).exists?(user: user)
            return false unless session.channel.subscription

            user && ::StripeDb::Subscription.joins(:stripe_plan).exists?(status: %i[active trialing], user: user,
                                                                         stripe_plan: session.channel.subscription.plans, stripe_plans: { im_replays: true })
          end.call
        end
        # RECORDINGS RULES
        can :purchase, Recording do |recording|
          user_cache_key = user.try(:cache_key)
          Rails.cache.fetch("ability/purchase_access/#{recording.cache_key}/#{user_cache_key}") do
            lambda do
              return false if recording.organizer == user
              return false if recording.free?
              return false if recording.private?

              return false if user.present? && PendingRefund.where(user: user,
                                                                   payment_transaction: recording.payment_transactions).present?

              participant_id = user.try(:participant_id)
              recording.recording_members.where(participant_id: participant_id).blank?
            end.call
          end
        end

        can :purchase_with_system_credit, Recording do |recording|
          can?(:purchase, recording) && user.system_credit_balance >= recording.purchase_price
        end

        can :take_for_free, Recording do |recording|
          user_cache_key = user.try(:cache_key)
          recording.free? && Rails.cache.fetch("ability/free_access/#{recording.cache_key}/#{user_cache_key}") do
            lambda do
              return false if recording.organizer == user
              return false if recording.private?

              return false if user.present? && PendingRefund.where(user: user,
                                                                   payment_transaction: recording.payment_transactions).present?

              participant_id = user.try(:participant_id)

              recording.recording_members.where(participant_id: participant_id).blank?
            end.call
          end
        end

        return if user.nil?

        ### LIVE OPT OUT DEFINITIONS
        can :live_opt_out_and_get_money_refund, Session do |session|
          user_cache_key = user.try(:cache_key) # could be not logged in/nil
          Rails.cache.fetch("ability/live_opt_out_and_get_money_refund/#{session.cache_key}/#{user_cache_key}") do
            can?(:live_opt_out, session) \
              && session.payment_transactions.live_access.success.not_archived.where(user_id: user.id).present? \
              && (BraintreeRefundCoefficient.new(session).could_be_full_refund_in_original_payment_type? || session.has_co_presenter?(user.presenter_id)) # because if co-presenter - can opt out at any time prior to session start and get full refund
          end
        end

        can :live_opt_out_and_get_full_system_credit_refund, Session do |session|
          user_cache_key = user.try(:cache_key) # could be not logged in/nil
          user.present? && Rails.cache.fetch("ability/live_opt_out_and_get_full_system_credit_refund/#{session.cache_key}/#{user_cache_key}") do
            lambda do
              return false if user.participant_id.blank?

              actually_paid = session.payment_transactions.live_access.success.where(user_id: user.id).present? \
                || SystemCreditEntry.live_access.where(commercial_document: session,
                                                       participant_id: user.participant_id).present?

              actually_paid \
                && (can?(:opt_out_as_immersive_participant,
                         session) || can?(:opt_out_as_livestream_participant, session)) \
                && BraintreeRefundCoefficient.new(session).could_be_full_refund_in_original_payment_type?
            end.call
          end
        end

        can :live_opt_out_without_refund, Session do |session|
          user_cache_key = user.try(:cache_key) # could be not logged in/nil
          user.present? && Rails.cache.fetch("ability/live_opt_out_without_refund/#{session.cache_key}/#{user_cache_key}") do
            lambda do
              return false if user.participant_id.blank?

              return false if can?(:live_opt_out_and_get_money_refund, session)
              return false if can?(:live_opt_out_and_get_full_system_credit_refund, session)
              return false if !can?(:opt_out_as_immersive_participant,
                                    session) && !can?(:opt_out_as_livestream_participant, session)

              transaction = session.payment_transactions.live_access.success.where(user_id: user.id).last \
                || SystemCreditEntry.live_access.where(commercial_document: session,
                                                       participant_id: user.participant_id).last

              return true if transaction.blank?

              (transaction.amount.to_f * BraintreeRefundCoefficient.new(session).coefficient).zero?
            end.call
          end
        end

        can :live_opt_out_with_partial_sys_credit_refund, Session do |session|
          user_cache_key = user.try(:cache_key) # could be not logged in/nil
          user.present? && Rails.cache.fetch("ability/live_opt_out_with_partial_sys_credit_refund/#{session.cache_key}/#{user_cache_key}") do
            lambda do
              return false if user.participant_id.blank?

              return false if can?(:live_opt_out_and_get_money_refund, session)
              return false if can?(:live_opt_out_and_get_full_system_credit_refund, session)
              return false if !can?(:opt_out_as_immersive_participant,
                                    session) && !can?(:opt_out_as_livestream_participant, session)

              transaction = session.payment_transactions.live_access.success.where(user_id: user.id).last \
                || SystemCreditEntry.live_access.where(commercial_document: session,
                                                       participant_id: user.participant_id).last

              return false if transaction.blank?

              refund_amount = transaction.amount.to_f * BraintreeRefundCoefficient.new(session).coefficient

              refund_amount.positive? && refund_amount < transaction.amount
            end.call
          end
        end

        ### LIVE OPT OUT DEFINITIONS

        ### VOD OPT OUT DEFINITIONS
        can :vod_opt_out_and_get_money_refund, Session do |_session|
          # user_cache_key = user.try(:cache_key) # could be not logged in/nil
          # Rails.cache.fetch("ability/vod_opt_out_and_get_money_refund/#{session.cache_key}/#{user_cache_key}") do
          #  lambda do
          #    return false if user.participant.blank?
          #    return false if session.completely_free?
          #    return false if session.braintree_transactions.vod_access.not_voided.where(user_id: user.id).blank?

          #    member = session.recorded_members.where(participant_id: user.participant_id).first
          #    member.present? && member.video_views_count.zero?
          #  end.call
          # end
          false
        end

        can :vod_opt_out_and_get_full_system_credit_refund, Session do |_session|
          # user_cache_key = user.try(:cache_key) # could be not logged in/nil
          # Rails.cache.fetch("ability/vod_opt_out_and_get_full_system_credit_refund/#{session.cache_key}/#{user_cache_key}") do
          #  lambda do
          #    return false if user.participant.blank?

          #    actually_paid = session.braintree_transactions.vod_access.not_voided.where(user_id: user.id).present? \
          #      || SystemCreditEntry.vod_access.where(commercial_document: session, participant_id: user.participant_id).present?

          #    member = session.recorded_members.where(participant_id: user.participant_id).first

          #    actually_paid \
          #      && can?(:opt_out_as_recorded_member, session) \
          #      && member.present? && member.video_views_count.zero?
          #  end.call
          # end
          false
        end

        can :vod_opt_out_without_refund, Session do |_session|
          false
        end

        can :vod_opt_out_with_partial_sys_credit_refund, Session do |_session|
          false
        end

        ### VOD OPT OUT DEFINITIONS

        ### GENERAL OPT OUT DEFINITIONS
        can :opt_out_as_immersive_participant, Session do |session|
          user_cache_key = user.try(:cache_key) # could be not logged in/nil
          user.present? && !session.started? && !session.cancelled? && !session.finished? && Rails.cache.fetch("ability/opt_out_as_immersive_participant/#{session.cache_key}/#{user_cache_key}") do
            lambda do
              return false if session.status.to_s == Session::Statuses::REQUESTED_FREE_SESSION_REJECTED

              if session.has_co_presenter?(user.presenter_id)
                return true
              end

              session.has_immersive_participant?(user.participant_id)
            end.call
          end
        end

        can :opt_out_as_livestream_participant, Session do |session|
          user_cache_key = user.try(:cache_key) # could be not logged in/nil
          user.present? && !session.started? && !session.finished? && !session.cancelled? && Rails.cache.fetch("ability/opt_out_as_livestream_participant/#{session.cache_key}/#{user_cache_key}") do
            lambda do
              return false if user.participant_id.blank?
              return false if session.status.to_s == Session::Statuses::REQUESTED_FREE_SESSION_REJECTED

              session.livestreamers.where(participant_id: user.participant_id).present?
            end.call
          end
        end

        can :opt_out_as_recorded_member, Session do |session|
          user_cache_key = user.try(:cache_key) # could be not logged in/nil
          user.present? && Rails.cache.fetch("ability/opt_out_as_recorded_member/#{session.cache_key}/#{user_cache_key}") do
            lambda do
              return false if user.participant_id.blank?

              session.recorded_members.where(participant_id: user.participant_id).present?
            end.call
          end
        end

        can :live_opt_out, Session do |session|
          can?(:opt_out_as_immersive_participant, session) || can?(:opt_out_as_livestream_participant, session)
        end

        can :vod_opt_out, Session do |session|
          can?(:opt_out_as_recorded_member, session)
        end

        can :change_participation_type, Session do |_session|
          false
          # can?(:live_opt_out, session)
        end

        can :accept_or_reject_invitation, Session do |session|
          user_cache_key = user.try(:cache_key) # could be not logged in/nil
          user.present? && Rails.cache.fetch("ability/accept_or_reject_invitation/#{session.cache_key}/#{user_cache_key}") do
            lambda do
              return false if session.finished? || session.cancelled? || session.stopped?
              return false if session.status.to_s == Session::Statuses::REQUESTED_FREE_SESSION_PENDING

              return false if session.livestreamers.where(participant_id: user.participant_id).present?

              invited_as_co_presenter = user.presenter.present? && session.session_invited_immersive_co_presenterships.where(presenter: user.presenter).pending.present?
              return true if invited_as_co_presenter

              invited_for_immersive = user.participant_id.present? && session.session_invited_immersive_participantships.where(participant_id: user.participant_id).pending.present?
              invited_for_livestream = user.participant_id.present? && session.session_invited_livestream_participantships.where(participant_id: user.participant_id).pending.present?
              invited_as_participant = invited_for_immersive || invited_for_livestream
              invited_as_participant && session.published?
            end.call
          end
        end

        can :accept_or_reject_invitation, Channel do |channel|
          user_cache_key = user.try(:cache_key) # could be not logged in/nil
          user.present? && Rails.cache.fetch("ability/accept_or_reject_invitation/#{channel.cache_key}/#{user_cache_key}") do
            lambda do
              return false if channel.organizer == user
              return false if user.presenter_id.blank?

              channel.channel_invited_presenterships.pending.exists?(presenter_id: user.presenter_id)
            end.call
          end
        end

        can :accept_or_reject_invitation, Organization do |organization|
          user_cache_key = user.try(:cache_key) # could be not logged in/nil
          user.present? && Rails.cache.fetch("ability/accept_or_reject_invitation/#{organization.cache_key}/#{user_cache_key}") do
            lambda do
              user.organization_memberships_participants.pending.exists?(organization: organization)
            end.call
          end
        end

        can :change_status_as_participant, SessionInvitedImmersiveParticipantship do |participantship|
          return false unless user

          user_cache_key = user.try(:cache_key) # could be not logged in/nil
          Rails.cache.fetch("ability/accept_or_reject_immersive_invitation/#{participantship.cache_key}/#{user_cache_key}") do
            lambda do
              participantship.participant_id == user.participant&.id \
              && participantship.status == ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING
            end.call
          end
        end

        can :change_status_as_participant, SessionInvitedLivestreamParticipantship do |participantship|
          return false unless user

          user_cache_key = user.try(:cache_key) # could be not logged in/nil
          Rails.cache.fetch("ability/accept_or_reject_livestream_invitation/#{participantship.cache_key}/#{user_cache_key}") do
            lambda do
              participantship.participant_id == user.participant&.id \
              && participantship.status == ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING
            end.call
          end
        end

        can :reject_invitation, SessionInvitedImmersiveParticipantship do |participantship|
          can?(:change_status_as_participant, participantship)
        end

        can :reject_invitation, SessionInvitedLivestreamParticipantship do |participantship|
          can?(:change_status_as_participant, participantship)
        end

        can :accept_invitation_without_paying, SessionInvitedImmersiveParticipantship do |participantship|
          return false unless user

          session = participantship.session
          user_cache_key = user.try(:cache_key) # could be not logged in/nil

          Rails.cache.fetch("ability/accept_immersive_invitation_without_paying/#{participantship.cache_key}/#{session.cache_key}/#{user_cache_key}") do
            lambda do
              return false unless participantship.status == ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING
              return false unless participantship.participant_id == user.participant&.id

              immersive_purchase_price = session.immersive_purchase_price
              return false unless immersive_purchase_price.present? && immersive_purchase_price.zero?

              true
            end.call
          end
        end

        can :accept_invitation_without_paying, SessionInvitedLivestreamParticipantship do |participantship|
          return false unless user

          session = participantship.session
          user_cache_key = user.try(:cache_key) # could be not logged in/nil

          Rails.cache.fetch("ability/accept_livestream_invitation_without_paying/#{participantship.cache_key}/#{session.cache_key}/#{user_cache_key}") do
            lambda do
              return false unless participantship.status == ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING
              return false unless participantship.participant_id == user.participant&.id

              livestream_purchase_price = session.livestream_purchase_price
              return false unless livestream_purchase_price.present? && livestream_purchase_price.zero?

              true
            end.call
          end
        end

        # no need in caching - rarely executed(only when accepting session invitation)
        can :accept_co_presenter_invitation_paid_by_organizer, Session do |session|
          user.present? && lambda do
            return false if session.finished? || session.cancelled?

            return false if session.livestreamers.where(participant_id: user.participant_id).present?

            session.organizer_abstract_session_pay_promises.any? { |promise| promise.co_presenter.email == user.email }
          end.call
        end

        # RECORDINGS RULES
        can :opt_as_recording_participant, Recording do |recording|
          participant_id = user.try(:participant_id)
          recording.recording_members.where(participant_id: participant_id).present?
        end

        can :subscribe, Subscription do |subscription|
          user && subscription && subscription.user != user && lambda do
            subscription.enabled && subscription.plans.exists?(im_enabled: true) && cannot?(:unsubscribe, subscription)
          end.call
        end

        can :subscribe_as_gift_for, User do |recipient, subscription|
          user && recipient && user != recipient && subscription && subscription.user != recipient && lambda do
            subscription.enabled && subscription.plans.exists?(im_enabled: true) &&
              !::StripeDb::Subscription.exists?(user: recipient, stripe_plan: subscription.plans,
                                                status: %i[active trialing])
          end.call
        end

        can :unsubscribe, Subscription do |subscription|
          user && subscription && subscription.user != user && lambda do
            ::StripeDb::Subscription.exists?(user: user, stripe_plan: subscription.plans, status: %i[active trialing])
          end.call
        end
      end
    end
  end
end
