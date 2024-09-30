# frozen_string_literal: true

module SessionJobs
  class NotifyUnnotifiedInvitedParticipantsJob < ApplicationJob
    def perform(session_id)
      session = Session.find(session_id)
      return unless session.published?

      session.session_invited_immersive_participantships.where(invitation_sent_at: nil).find_each do |participantship|
        participant = participantship.participant
        time = Time.now
        Immerss::SessionMultiFormatMailer.new.participant_invited_to_abstract_session(session.id, participant.id).deliver
        participant.user.notify_about_invitation
        participantship.update_columns(invitation_sent_at: time, updated_at: time)
        session.session_invited_livestream_participantships
               .where(invitation_sent_at: nil, participant: participant)
               .update_all(invitation_sent_at: time, updated_at: time)
      end

      session.session_invited_livestream_participantships.where(invitation_sent_at: nil).find_each do |participantship|
        participant = participantship.participant
        time = Time.now
        Immerss::SessionMultiFormatMailer.new.participant_invited_to_abstract_session(session.id, participant.id).deliver
        participant.user.notify_about_invitation
        participantship.update_columns(invitation_sent_at: time, updated_at: time)
      end
    end
  end
end
