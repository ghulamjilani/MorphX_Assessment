# frozen_string_literal: true

module SessionJobs
  class EditInvitedUsersJob < ApplicationJob
    def perform(session_id, inviter_user_id, invited_users_attributes)
      invited_users_attributes.each(&:symbolize_keys!)
      session = Session.find(session_id)
      inviter_user = User.find(inviter_user_id)

      existing_invited_immersive_participant_emails = SessionInvitedImmersiveParticipantship.where(session_id: session.id).joins(participant: :user).pluck(:email)
      existing_invited_livestream_participant_emails = SessionInvitedLivestreamParticipantship.where(session_id: session.id).joins(participant: :user).pluck(:email)
      existing_invited_immersive_co_presenter_emails = SessionInvitedImmersiveCoPresentership.where(session_id: session.id).joins(presenter: :user).pluck(:email)

      # check immersive participants
      session.session_invited_immersive_participantships.each do |siip|
        participant = siip.participant

        next if invited_users_attributes.select do |h|
          [ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM, ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE].include?(h[:state])
        end.pluck(:email).include?(participant.email)

        invited_participantship = session.session_invited_immersive_participantships.detect do |ip|
          ip.participant == participant
        end

        invited_participantship.destroy if invited_participantship.present?
      end

      # check livestream participants
      session.session_invited_livestream_participantships.each do |siip|
        participant = siip.participant

        next if invited_users_attributes.select do |h|
          [ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM, ModelConcerns::Session::HasInvitedUsers::States::LIVESTREAM].include?(h[:state])
        end.pluck(:email).include?(participant.email)

        invited_participantship = session.session_invited_livestream_participantships.detect do |ip|
          ip.participant == participant
        end

        invited_participantship.destroy if invited_participantship.present?
      end

      # check co-presenters
      session.session_invited_immersive_co_presenterships.each do |sicp|
        presenter = sicp.presenter

        next if invited_users_attributes.select do |h|
          h[:state] == ModelConcerns::Session::HasInvitedUsers::States::CO_PRESENTER
        end.pluck(:email).include?(presenter.email)

        invited_presentership = session.session_invited_immersive_co_presenterships.detect do |invited_co_presenterships|
          invited_co_presenterships.presenter == presenter
        end

        invited_presentership.destroy if invited_presentership.present?
      end

      # Invite
      to_invite_immersive = invited_users_attributes.select do |h|
        [ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM, ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE].include?(h[:state])
      end

      to_invite_immersive.each do |hash|
        email = hash[:email] or raise

        if existing_invited_immersive_participant_emails.include?(email)
          next
        elsif (user = User.find_by(email: email.to_s.downcase))
          user.create_participant! if user.participant.blank?
          session.session_invited_immersive_participantships.create!(participant: user.participant, session: session)
        else
          user = User.invite!({ email: email }, inviter_user) do |u|
            u.before_create_generic_callbacks_and_skip_validation
            u.skip_invitation = true
          end

          if user.valid?
            user.create_participant! if user.participant.blank?
            session.session_invited_immersive_participantships.create!(participant: user.participant, session: session)
          else
            session.session_invited_immersive_participantships.create!(
              participant: Participant.new(user: User.new(email: email)), session: session
            )
          end
        end
      rescue StandardError => e
        Airbrake.notify(e,
                        {
                          message: 'Failed to assign invited interactive participant to session',
                          session_id: session_id,
                          hash: hash
                        })
      end

      to_invite_livestream = invited_users_attributes.select do |h|
        h[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM || h[:state] == ModelConcerns::Session::HasInvitedUsers::States::LIVESTREAM
      end

      to_invite_livestream.each do |hash|
        email = hash[:email] or raise

        if existing_invited_livestream_participant_emails.include?(email)
          next
        elsif (user = User.find_by(email: email.to_s.downcase))
          user.create_participant! if user.participant.blank?
          session.session_invited_livestream_participantships.create!(participant: user.participant, session: session)
        else
          user = User.invite!({ email: email }, inviter_user) do |u|
            u.before_create_generic_callbacks_and_skip_validation
            u.skip_invitation = true
          end

          if user.valid?
            user.create_participant! if user.participant.blank?
            session.session_invited_livestream_participantships.create!(participant: user.participant, session: session)
          else
            session.session_invited_livestream_participantships.create!(
              participant: Participant.new(user: User.new(email: email)), session: session
            )
          end
        end
      rescue StandardError => e
        Airbrake.notify(e,
                        {
                          message: 'Failed to assign invited livestream participant to session',
                          session_id: session_id,
                          hash: hash
                        })
      end

      to_invite_co_presenters = invited_users_attributes.select do |h|
        h[:state] == ModelConcerns::Session::HasInvitedUsers::States::CO_PRESENTER
      end

      to_invite_co_presenters.each do |hash|
        email = hash[:email] or raise

        if existing_invited_immersive_co_presenter_emails.include?(email)
          next
        elsif (user = User.find_by(email: email.to_s.downcase))
          user.create_presenter! if user.presenter.blank?
          user.create_participant! if user.participant.blank?

          session.session_invited_immersive_co_presenterships.create!(presenter: user.presenter, session: session)
        else
          user = User.invite!({ email: email }, inviter_user) do |u|
            u.before_create_generic_callbacks_and_skip_validation
            u.skip_invitation = true
          end

          if user.valid?
            user.create_presenter! if user.presenter.blank?
            session.session_invited_immersive_co_presenterships.create!(presenter: user.presenter, session: session)
          else
            session.session_invited_immersive_co_presenterships.create!(
              presenter: Presenter.new(user: User.new(email: email)), session: session
            )
          end
        end
      end

      SessionJobs::NotifyUnnotifiedInvitedParticipantsJob.perform_async(session_id)
    end
  end
end
