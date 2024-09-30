# frozen_string_literal: true

module SessionJobs
  class AssignInvitedUsersJob < ApplicationJob
    sidekiq_options queue: :critical

    def perform(session_id, inviter_user_id, invited_users_attributes)
      session = Session.find(session_id)
      inviter_user = User.find(inviter_user_id)
      invited_users_attributes.each do |hash|
        hash.symbolize_keys!
        email = hash[:email] or raise
        raise unless ModelConcerns::Session::HasInvitedUsers::States::ALL.include?(hash[:state])

        if (user = User.find_by(email: email.to_s.downcase))
          user.create_participant! if user.participant.blank?

          if hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM ||
             hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE
            session.session_invited_immersive_participantships.create!(participant: user.participant, session: session)
          end

          if hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM ||
             hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::LIVESTREAM
            session.session_invited_livestream_participantships.create!(participant: user.participant, session: session)
          end
        else
          user = User.invite!({ email: email }, inviter_user) do |u|
            u.before_create_generic_callbacks_and_skip_validation
            u.skip_invitation = true
          end

          if user.valid?
            user.create_participant! if user.participant.blank?

            if hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM ||
               hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE
              session.session_invited_immersive_participantships.create!(participant: user.participant, session: session)
            end

            if hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM ||
               hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::LIVESTREAM
              session.session_invited_livestream_participantships.create!(participant: user.participant, session: session)
            end
          else
            if hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM || hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE
              session.session_invited_immersive_participantships.create!(
                participant: Participant.new(user: User.new(email: email)), session: session
              )
            end

            if hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM || hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::LIVESTREAM
              session.session_invited_livestream_participantships.create!(
                participant: Participant.new(user: User.new(email: email)), session: session
              )
            end
          end
        end
      rescue StandardError => e
        Airbrake.notify(e,
                        {
                          message: 'Failed to assign invited participant to session',
                          session_id: session_id,
                          hash: hash
                        })
      end

      SessionJobs::NotifyUnnotifiedInvitedParticipantsJob.perform_async(session_id)
    end
  end
end
