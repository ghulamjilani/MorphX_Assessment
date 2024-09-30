# frozen_string_literal: true

module AbilityLib
  class SessionAbility < AbilityLib::Base
    def service_admin_abilities
      @service_admin_abilities ||= {
        view_free_livestream: [Session],
        see_full_version_video: [Session],
        join_as_participant: [Session],
        join_as_livestreamer: [Session],
        join_immersive: [Session],
        obtain_recorded_access_to_free_session: [Session],
        obtain_free_trial_immersive_access: [Session],
        obtain_free_trial_livestream_access: [Session],
        obtain_immersive_access_to_free_session: [Session],
        obtain_livestream_access_to_free_session: [Session],
        access_as_subscriber: [Session],
        access_replay_as_subscriber: [Session],
        read: [Session]
      }
    end

    def load_permissions
      can :share, Session do |session|
        session.status.to_s != Session::Statuses::REQUESTED_FREE_SESSION_REJECTED && session.published?
      end

      can :email_share, Session do |session|
        # you may take rate limiting into account to avoid spamming #later
        user.persisted? && can?(:share, session)
      end

      can :view_livestream_as_guest, Session do |session|
        if user.persisted?
          false
        else
          session.published? && session.livestream_free && !session.only_subscription && session.age_restrictions.to_i.zero? && !session.private && !session.finished? && !session.cancelled?
        end
      end

      can :view_free_livestream, Session do |session|
        !session.stopped? && session.upcoming? && !session.cancelled? && session.published? && !session.private && !session.finished? &&
          session.livestream_free && (!session.only_subscription || (session.only_subscription && user.persisted? && ::StripeDb::Subscription.joins(:channel_subscription, :stripe_plan).exists?(
            status: %i[active trialing], user: user, subscriptions: { channel_id: session.channel.id }, stripe_plans: { im_livestreams: true }
          ))) && session.age_restrictions.to_i.zero?
      end

      can :view_livestream, Session do |session|
        lambda do
          return true if user == session.organizer

          can?(:view_free_livestream, session) || can?(:join_as_livestreamer, session) || can?(:view_livestream_as_guest, session)
        end.call
      end

      can :see_full_version_video, Session do |session|
        lambda do
          video = session.records.first
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

      # NOTE: user is signed_in/present
      can :join_as_participant, Session do |session|
        cache_key = "join_as_participant/#{session.cache_key}/#{user.cache_key}"

        user.persisted? && !session.stopped? && session.upcoming? && !session.cancelled? && Rails.cache.fetch(cache_key) do
          session.has_immersive_participant?(user.participant_id) && !session.room_members.banned.exists?(abstract_user: user)
        end
      end

      # NOTE: user is signed_in/present
      can :join_as_presenter, Session do |session|
        cache_key = "join_as_presenter/#{session.cache_key}/#{user.cache_key}"

        user.persisted? && !session.stopped? && session.upcoming? && !session.cancelled? && Rails.cache.fetch(cache_key) do
          user == session.organizer
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
        can?(:join_as_presenter, session) || can?(:join_as_co_presenter, session) || can?(:join_as_participant, session)
      end

      can :start_immersive, Session do |session|
        user.persisted? && session.webrtcservice? && (
          (can?(:join_as_presenter, session) && session.room.open?) ||
            (can?(:participate, session) && session.room.autostart && session.running?)
        )
      end

      can :join_immersive, Session do |session|
        user.persisted? && session.webrtcservice? && (
          can?(:start_immersive, session) ||
            (can?(:participate, session) && session.running?)
        )
      end

      # no need in caching(executed from sidekiq job)
      can :receive_session_start_reminders, Session do |session|
        lambda do
          return false if user.new_record?

          if user.session_reminders.exists?(session_id: session.id) || (user.presenter.present? && (user.presenter.primary_presenter?(session) || user.presenter.co_presenter?(session))) ||
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
        end.call
      end

      can :purchase_immersive_access, Session do |session|
        user_cache_key = user.try(:cache_key) # could be not logged in/nil
        Rails.cache.fetch("ability/purchase_immersive_access/#{session.cache_key}/#{user_cache_key}") do
          lambda do
            participant_id = user.try(:participant_id)

            if user.persisted?
              # fixes #1097
              return false if PendingRefund.where(user: user, payment_transaction: session.payment_transactions).present?

              # invited co-presenter
              if user.presenter.present? && session.session_invited_immersive_co_presenterships.where(presenter: user.presenter).pending.present?
                return true
              end
            end

            return false if user.persisted? && user.presenter.present? && user == session.organizer
            return false if session.finished? || !session.published? || session.cancelled? || !session.immersive_delivery_method? || session.immersive_free
            return false if session.immersive_purchase_price.zero?
            return false if user.persisted? && session.has_co_presenter?(user.try(:presenter_id))
            return false if user.persisted? && session.has_immersive_participant?(user.participant_id) # already bought
            return false if session.status.to_s == Session::Statuses::REQUESTED_FREE_SESSION_PENDING
            return false if session.only_subscription && user.persisted? && !(::StripeDb::Subscription.joins(:channel_subscription).exists?(
              user: user, subscriptions: { channel_id: session.channel.id }
            ) || session.channel.free_subscriptions.in_action.with_features(:interactives).exists?(user: user))

            # NOTE: - from this line user is not a co-presenter for sure

            if session.private?
              return user.persisted? && session.session_invited_immersive_participantships.where(participant_id: user.participant_id).pending.present?
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

            return false if user.persisted? && user.presenter.present? && (user.presenter.co_presenter?(session) || user.presenter.primary_presenter?(session))

            return false if session.only_subscription && !(::StripeDb::Subscription.joins(:channel_subscription).exists?(
              user: user, subscriptions: { channel_id: session.channel.id }
            ) || session.channel.free_subscriptions.in_action.with_features(:livestreams).exists?(user: user))

            # fixes #1097
            return false if user.persisted? && PendingRefund.where(user: user, payment_transaction: session.payment_transactions).present?

            invited_as_co_presenter = user.persisted? && user.presenter.present? && session.session_invited_immersive_co_presenterships.where(presenter: user.presenter).pending.present?
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
            return false if session.recorded_purchase_price.blank? || session.recorded_purchase_price&.zero?
            return false if !session.published? || session.cancelled? || !session.recorded_delivery_method?
            return false if user.present? && PendingRefund.where(user: user,
                                                                 payment_transaction: session.payment_transactions).present?

            participant_id = user.try(:participant_id)
            return false if session.recorded_members.exists?(participant_id: participant_id)

            video = session.records.first
            return false unless video

            if video.only_subscription
              return video.only_ppv && (::StripeDb::Subscription.joins(:channel_subscription).exists?(
                status: %i[active trialing], user: user, subscriptions: { channel_id: session.channel.id }
              ) || session.channel.free_subscriptions.in_action.with_features(:replays).exists?(user: user))
            end

            true
          end.call
        end
      end

      can :obtain_recorded_access_to_free_session, Session do |session|
        user_cache_key = user.try(:cache_key)
        !session.recorded_purchase_price.nil? && session.recorded_purchase_price&.zero? && Rails.cache.fetch("ability/obtain_recorded_access_to_free_session/#{session.cache_key}/#{user_cache_key}") do
          lambda do
            return false if session.organizer == user

            participant_id = user.try(:participant_id)

            if !session.published? || session.cancelled? || !session.recorded_delivery_method?
              return false
            end

            return false if user.persisted? && PendingRefund.where(user: user,
                                                                   payment_transaction: session.payment_transactions).present?

            session.recorded_members.where(participant_id: participant_id).blank?
          end.call
        end
      end

      # NOTE: - this ability check has to ignore whether VOD is already available or not(!)
      # because this is check additionally and separately
      can :purchase_recorded_access_with_system_credit, Session do |session|
        can?(:purchase_recorded_access, session) && user.system_credit_balance >= session.recorded_purchase_price
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
            return false if session.only_ppv
            return false if session.only_subscription && !::StripeDb::Subscription.joins(:channel_subscription).exists?(
              status: %i[active trialing], user: user, subscriptions: { channel_id: session.channel.id }
            )
            return false if session.finished? || session.cancelled? || !session.immersive_delivery_method?

            participant_id = user.try(:participant_id)
            presenter_id = user.try(:presenter_id)

            already_member = session.session_participations.where(participant_id: participant_id).present? || \
                             session.session_co_presenterships.where(presenter_id: presenter_id).present?
            return false if already_member

            invited_as_co_presenter = session.session_invited_immersive_co_presenterships.where(presenter_id: presenter_id).where.not(status: 'rejected').present?
            return false if invited_as_co_presenter

            return false if session.livestreamers.where(participant_id: participant_id).present?

            # fixes #1097
            return false if user.persisted? && PendingRefund.where(user: user,
                                                                   payment_transaction: session.payment_transactions).present?

            return false unless session.interactive_slots_available?

            return false if Session.joins(:session_participations)
                                   .where(session_participations: { session_id: session.id,
                                                                    free_trial: true }).count >= session.immersive_free_slots

            Session.joins(:session_participations)
                   .free_trial_for_first_time_participants
                   .where(channel_id: session.channel_id)
                   .where(session_participations: { participant_id: participant_id, free_trial: true }).blank? \
                && Session.joins(:livestreamers)
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
            presenter_id = user.try(:presenter_id)

            return false if session.livestreamers.where(participant_id: participant_id).present?
            return false if session.session_participations.where(participant_id: participant_id).present?
            return false if session.session_co_presenterships.where(presenter_id: presenter_id).present?

            invited_as_co_presenter = user.persisted? && user.presenter.present? && session.session_invited_immersive_co_presenterships.where(presenter: user.presenter).pending.present?
            return false if invited_as_co_presenter

            # fixes #1097
            return false if user.persisted? && PendingRefund.where(user: user,
                                                                   payment_transaction: session.payment_transactions).present?

            return false if Session.joins(:livestreamers)
                                   .where(livestreamers: { session_id: session.id,
                                                           free_trial: true }).count >= session.livestream_free_slots

            Session.joins(:livestreamers)
                   .free_trial_for_first_time_participants
                   .where(channel_id: session.channel_id)
                   .where(livestreamers: { participant_id: participant_id, free_trial: true }).blank? \
                && Session.joins(:session_participations)
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
            return false if session.only_ppv
            return false if session.only_subscription && user.persisted? && !(::StripeDb::Subscription.joins(:channel_subscription).exists?(
              status: %i[active trialing], user: user, subscriptions: { channel_id: session.channel.id }
            ) || session.channel.free_subscriptions.in_action.with_features(:interactives).exists?(user: user))

            return true if (user.persisted? && ::StripeDb::Subscription.joins(:channel_subscription, :stripe_plan).exists?(
              status: %i[active trialing], user: user, subscriptions: { channel_id: session.channel.id }, stripe_plans: { im_interactives: true }
            )) || session.channel.free_subscriptions.in_action.with_features(:interactives).exists?(user: user)

            return false if session.immersive_purchase_price.present? && !session.immersive_purchase_price.zero?
            return false if session.finished? || session.cancelled?

            invited_as_co_presenter = user.persisted? && user.presenter.present? && session.session_invited_immersive_co_presenterships.where(presenter: user.presenter).pending.present?
            return true if invited_as_co_presenter

            return false unless session.immersive_delivery_method?

            participant_id = user.try(:participant_id)
            presenter_id = user.try(:presenter_id)

            return false if session.livestreamers.where(participant_id: participant_id).present?

            # fixes #1097
            return false if user.persisted? && PendingRefund.where(user: user, payment_transaction: session.payment_transactions).present?

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
            return false if session.only_ppv
            return false if session.only_subscription && user.persisted? && !::StripeDb::Subscription.joins(:channel_subscription).exists?(
              status: %i[active trialing], user: user, subscriptions: { channel_id: session.channel.id }
            )

            participant_id = user.try(:participant_id)
            presenter_id = user.try(:presenter_id)

            # not already a member
            return false if session.livestreamers.where(participant_id: participant_id).present?
            return false if session.session_participations.where(participant_id: participant_id).present?
            return false if session.session_co_presenterships.where(presenter_id: presenter_id).present?

            invited_as_co_presenter = user.persisted? && user.presenter.present? && session.session_invited_immersive_co_presenterships.where(presenter: user.presenter).pending.present?
            return false if invited_as_co_presenter

            # fixes #1097
            return false if user.persisted? && PendingRefund.where(user: user,
                                                                   payment_transaction: session.payment_transactions).present?

            session.livestreamers.where(participant_id: participant_id).blank?
          end.call
        end
      end

      can :access_as_subscriber, Session do |session|
        user.persisted? && lambda do
          # channel has no plans
          return false if session.only_ppv
          return false unless session.livestream_delivery_method?
          return false if session.livestream_purchase_price.nil?
          return true if user.persisted? && session.channel.free_subscriptions.in_action.with_features(:livestreams).exists?(user: user)
          return false unless session.channel.subscription

          user.persisted? && ::StripeDb::Subscription.joins(:channel_subscription, :stripe_plan).exists?(
            status: %i[active trialing], user: user, subscriptions: { channel_id: session.channel.id }, stripe_plans: { im_livestreams: true }
          )
        end.call
      end

      can :access_replay_as_subscriber, Session do |session|
        user.persisted? && lambda do
          video = session.records.first
          # channel has no plans
          return false if video.blank?
          return false unless session.recorded_delivery_method?
          return false unless session.recorded_purchase_price.positive?
          return false if video.only_ppv
          return true if video.only_subscription && user.persisted? && ::StripeDb::Subscription.joins(:channel_subscription, :stripe_plan).exists?(
            status: %i[active trialing], user: user, subscriptions: { channel_id: session.channel.id }, stripe_plans: { im_replays: true }
          )

          return true if user.persisted? && session.channel.free_subscriptions.in_action.with_features(:replays).exists?(user: user)

          return false unless session.channel.subscription

          user.persisted? && ::StripeDb::Subscription.joins(:stripe_plan, :channel_subscription).exists?(
            status: %i[active trialing], user: user, subscriptions: { channel_id: session.channel.id }, stripe_plans: { im_replays: true }
          )
        end.call
      end

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
        user.persisted? && Rails.cache.fetch("ability/live_opt_out_and_get_full_system_credit_refund/#{session.cache_key}/#{user_cache_key}") do
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
        user.persisted? && Rails.cache.fetch("ability/live_opt_out_without_refund/#{session.cache_key}/#{user_cache_key}") do
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
        user.persisted? && Rails.cache.fetch("ability/live_opt_out_with_partial_sys_credit_refund/#{session.cache_key}/#{user_cache_key}") do
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
        user.persisted? && !session.started? && !session.cancelled? && !session.finished? && Rails.cache.fetch("ability/opt_out_as_immersive_participant/#{session.cache_key}/#{user_cache_key}") do
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
        user.persisted? && !session.started? && !session.finished? && !session.cancelled? && Rails.cache.fetch("ability/opt_out_as_livestream_participant/#{session.cache_key}/#{user_cache_key}") do
          lambda do
            return false if user.participant_id.blank?
            return false if session.status.to_s == Session::Statuses::REQUESTED_FREE_SESSION_REJECTED

            session.livestreamers.where(participant_id: user.participant_id).present?
          end.call
        end
      end

      can :opt_out_as_recorded_member, Session do |session|
        user_cache_key = user.try(:cache_key) # could be not logged in/nil
        user.persisted? && Rails.cache.fetch("ability/opt_out_as_recorded_member/#{session.cache_key}/#{user_cache_key}") do
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
        user.persisted? && Rails.cache.fetch("ability/accept_or_reject_invitation/#{session.cache_key}/#{user_cache_key}") do
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

      # no need in caching - rarely executed(only when accepting session invitation)
      can :accept_co_presenter_invitation_paid_by_organizer, Session do |session|
        user.persisted? && lambda do
          return false if session.finished? || session.cancelled?

          return false if session.livestreamers.where(participant_id: user.participant_id).present?

          session.organizer_abstract_session_pay_promises.any? { |promise| promise.co_presenter.email == user.email }
        end.call
      end

      can :edit, Session do |session|
        lambda do
          return false unless !session.finished? && !session.cancelled? && session.status.to_s != Session::Statuses::REQUESTED_FREE_SESSION_REJECTED

          user.has_channel_credential?(session.channel, :edit_session)
        end.call
      end

      can :cancel, Session do |session|
        lambda do
          return false if session.finished? || session.cancelled? || session.started? || session.active?

          user.has_channel_credential?(session.channel, :cancel_session)
        end.call
      end

      can :clone, Session do |session|
        user.has_channel_credential?(session.channel, :clone_session)
      end

      can :invite_to_session, Session do |session|
        session.presenter.user == user || user.has_channel_credential?(session.channel, :invite_to_session)
      end

      can :edit_ban_list, Session do |session|
        can?(:invite_to_session, session)
      end

      can :start, Session do |session|
        user.has_channel_credential?(session.channel, :start_session)
      end

      can :end, Session do |session|
        user.has_channel_credential?(session.channel, :end_session)
      end

      can :add_products, Session do |session|
        user.has_channel_credential?(session.channel, :add_products_to_session)
      end

      can :have_in_wishlist, Session do |session|
        user_cache_key = user.try(:cache_key) # could be not logged in/nil
        Rails.cache.fetch("ability/have_in_wishlist/#{session.cache_key}/#{user_cache_key}") do
          lambda do
            return false if session.status.to_s == Session::Statuses::REQUESTED_FREE_SESSION_REJECTED

            # display it in UI as if it is possible
            return true if user.new_record?

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

      can :request_another_time, Session do |session|
        # TODO: - prevent team members from requesting sessions?
        # TODO - update config/initializers/rack-attack.rb ?

        user.persisted? && !session.finished? && !session.cancelled? && user != session.organizer
      end

      # no need in caching - rarely executed(only when Review modal window is displayed after clicking *Add review*)
      can :create_or_update_review_comment, Session do |session|
        lambda do
          return false unless can?(:rate, session)

          return true if user == session.organizer

          mandatory_dimensions = ::Session::RateKeys::MANDATORY
          mandatory_dimensions.map do |dimension|
            Rate.exists?(rater_id: user.id, rateable: session, dimension: dimension)
          end.all?
        end.call
      end

      can :toggle_remind_me_session, Session do |session|
        session.organizer != user && session.upcoming? && !session.in_progress? && !session.running?
      end

      can :move_between_channels, Session do |session|
        lambda do
          channel = session.channel
          return true if session.presenter_id == user.presenter_id
          return true if channel.organizer == user
          return true if channel.organization&.organization_memberships_active&.exists?(role: 'administrator', user_id: user.id)
          return true if user.presenter && channel.channel_invited_presenterships.exists?(
            presenter_id: user.presenter.id, status: 'accepted'
          )
          return true if user.has_channel_credential?(session.channel, :edit_replay)

          false
        end.call
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

      can :obtain_participation_without_invite, Session do |session|
        cache_key = "obtain_participation_without_invite/#{session.cache_key}/#{user.cache_key}"

        !session.stopped? && session.upcoming? && !session.cancelled? && Rails.cache.fetch(cache_key) do
          ObtainImmersiveAccessToSession.new(session, user).could_be_obtained_and_not_pending_invitee?
        end
      end

      can :rate, Session do |session|
        lambda do
          return false unless user.persisted? && user.confirmed?

          return false if cannot?(:read, session)

          return false if session.cancelled?

          return false unless session.started? || session.finished?

          return true if user == session.organizer

          return false if session.room_members.banned.exists?(abstract_user: user)

          return true if session.has_immersive_participant?(user.participant_id)

          return true if session.has_livestream_participant?(user.participant_id)

          can?(:see_full_version_video, session)
        end.call
      end

      can :comment, Session do |session|
        lambda do
          return false unless user.persisted?

          can?(:read, session)
        end.call
      end

      can :read_im_conversation, Session do |session|
        Rails.cache.fetch("channel_ability/read_im_conversation/session/#{session.cache_key}/#{user_or_guest.cache_key}", expires_in: 1.hour) do
          lambda do
            return false unless Rails.application.credentials.dig(:global, :instant_messaging, :enabled)
            return false unless Rails.application.credentials.dig(:global, :instant_messaging, :conversations, :sessions, :enabled)

            session.allow_chat?
          end.call
        end
      end

      can :create_im_message, Session do |session|
        lambda do
          return false unless user_or_guest.persisted?
          return false if session.im_conversation_participants.banned.exists?(abstract_user: user_or_guest)
          return false if session.finished?

          can?(:read_im_conversation, session)
        end.call
      end

      can :moderate_im_conversation, Session do |session|
        Rails.cache.fetch("channel_ability/moderate_im_conversation/session/#{session.id}/#{user.cache_key}") do
          lambda do
            return false unless user.persisted?
            return false unless Rails.application.credentials.dig(:global, :instant_messaging, :enabled)
            return false unless Rails.application.credentials.dig(:global, :instant_messaging, :conversations, :sessions, :enabled)
            return false unless session.allow_chat?

            user.has_channel_credential?(session.channel, %i[moderate_session_conversation])
          end.call
        end
      end

      can :track_view, Session do |session|
        lambda do
          return false if session.interactive_delivery_method? # TODO: remove after livestream is available for interactive session
          return false unless session.livestream_delivery_method?
          return false unless session.in_progress?
          return false if session.finished?

          can?(:view_livestream, session)
        end.call
      end
    end
  end
end
