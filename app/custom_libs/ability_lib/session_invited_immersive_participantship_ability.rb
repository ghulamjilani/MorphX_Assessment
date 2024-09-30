# frozen_string_literal: true

module AbilityLib
  class SessionInvitedImmersiveParticipantshipAbility < AbilityLib::Base
    def service_admin_abilities
      @service_admin_abilities ||= {}
    end

    def load_permissions
      return unless user.persisted?

      can :change_status_as_participant, SessionInvitedImmersiveParticipantship do |participantship|
        user_cache_key = user.try(:cache_key) # could be not logged in/nil
        Rails.cache.fetch("ability/accept_or_reject_immersive_invitation/#{participantship.cache_key}/#{user_cache_key}") do
          lambda do
            participantship.participant_id == user.participant&.id \
            && participantship.status == ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING
          end.call
        end
      end

      can :reject_invitation, SessionInvitedImmersiveParticipantship do |participantship|
        can?(:change_status_as_participant, participantship)
      end

      can :accept_invitation_without_paying, SessionInvitedImmersiveParticipantship do |participantship|
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

      can :destroy_invitation, SessionInvitedImmersiveParticipantship do |participantship|
        user_cache_key = user.try(:cache_key) # could be not logged in/nil
        Rails.cache.fetch("ability/destroy_immersive_invitation/#{participantship.cache_key}/#{user_cache_key}") do
          lambda do
            return false if participantship.status.eql?(ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED)

            session = participantship.session
            return true if session.presenter.user == user

            user.has_channel_credential?(session.channel, :invite_to_session)
          end.call
        end
      end
    end
  end
end
