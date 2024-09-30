# frozen_string_literal: true

module AbilityLib
  class RecordingAbility < AbilityLib::Base
    def service_admin_abilities
      @service_admin_abilities ||= {
        see_recording: [Recording],
        take_for_free: [Recording],
        read: [Recording]
      }
    end

    def load_permissions
      can :see_recording, Recording do |recording|
        lambda do
          return false unless recording.channel.organization.active_subscription_or_split_revenue?
          return true if recording.channel.organizer == user

          if recording.private || recording.only_ppv
            return false if user.new_record?
            return false unless recording.channel.organizer == user || recording.recording_members.where(participant_id: user.participant_id).present?
          elsif recording.only_subscription
            return false if user.new_record?

            return ::StripeDb::Subscription.joins(:channel_subscription).where(
              user: user, status: %i[active trialing], subscriptions: { channel_id: recording.channel_id }
            ).present? || recording.channel.free_subscriptions.in_action.with_features(:uploads).exists?(user: user)
          else
            return false if Rails.application.credentials.global[:enterprise] && !user.has_channel_credential?(
              recording.channel, :view_content
            )
            return true if recording.free?
            return true if user.persisted? && ::StripeDb::Subscription.joins(:channel_subscription, :stripe_plan).where(user: user, status: %i[active trialing],
                                                                                                                        subscriptions: { channel_id: recording.channel_id },
                                                                                                                        stripe_plans: { im_uploads: true }).present?
          end
          return true if recording.recording_members.exists?(participant_id: user&.participant_id)

          user.persisted? && recording.channel.free_subscriptions.in_action.with_features(:uploads).exists?(user: user)
        end.call
      end

      can :have_in_wishlist, Recording do |recording|
        recording.organizer != user
      end

      can :share, Recording do |recording|
        # you may take rate limiting into account to avoid spamming #later
        recording.channel.approved?
      end

      can :email_share, Recording do |recording|
        user.persisted? && can?(:share, recording)
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
            return false if participant_id && recording.recording_members.exists?(participant_id: participant_id)

            if recording.only_ppv
              if recording.only_subscription
                if user
                  return ::StripeDb::Subscription.joins(:channel_subscription).where(
                    user: user, subscriptions: { channel_id: recording.channel_id }
                  ).present? || recording.channel.free_subscriptions.in_action.with_features(:uploads).exists?(user: user)
                else
                  return false
                end
              else
                return true
              end
            elsif recording.only_subscription
              return false
            end
            true
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

            return false if user.persisted? && PendingRefund.exists?(user: user,
                                                                     payment_transaction: recording.payment_transactions)

            participant_id = user.try(:participant_id)

            recording.recording_members.where(participant_id: participant_id).blank?
          end.call
        end
      end

      # RECORDINGS RULES
      can :opt_as_recording_participant, Recording do |recording|
        participant_id = user.try(:participant_id)
        recording.recording_members.exists?(participant_id: participant_id)
      end

      can :read, Recording do |recording|
        cache_key = "read/#{recording.cache_key}/#{recording.try(:cache_key)}"
        Rails.cache.fetch(cache_key) do
          recording.done? && recording.published? && !recording.deleted_at
        end
      end

      can :review, Recording do |recording|
        lambda do
          return false unless user.persisted?

          return false if cannot?(:read, recording)

          can?(:see_recording, recording)
        end.call
      end

      can :comment, Recording do |recording|
        lambda do
          return false unless user.persisted?

          can?(:read, recording)
        end.call
      end

      can :rate, Recording do |recording|
        lambda do
          return false unless user.persisted?

          return false unless user.confirmed?

          return false if user == recording.organizer

          return false if cannot?(:read, recording)

          can?(:see_recording, recording)
        end.call
      end

      # no need in caching - rarely executed(only when Review modal window is displayed after clicking *Add review*)
      can :create_or_update_review_comment, Recording do |recording|
        lambda do
          return false unless can?(:rate, recording)

          return false if user == recording.organizer

          mandatory_dimensions = ::Recording::RateKeys::MANDATORY
          mandatory_dimensions.map do |dimension|
            Rate.exists?(rater_id: user.id, rateable: recording, dimension: dimension)
          end.all?
        end.call
      end

      can :track_view, Recording do |recording|
        can?(:see_recording, recording)
      end
    end
  end
end
