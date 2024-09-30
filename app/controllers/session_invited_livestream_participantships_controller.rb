# frozen_string_literal: true

class SessionInvitedLivestreamParticipantshipsController < ApplicationController
  def forcefully_close
    session = Session.find(params[:session_id])
    obj = session
          .session_invited_livestream_participantships
          .pending
          .where(participant_id: current_user.participant_id)
          .first

    respond_to_blocking_notification_close_request(obj)
  end
end
