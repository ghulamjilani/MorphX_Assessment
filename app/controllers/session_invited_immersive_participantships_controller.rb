# frozen_string_literal: true

class SessionInvitedImmersiveParticipantshipsController < ApplicationController
  def forcefully_close
    session = Session.find(params[:session_id])
    obj = session.session_invited_immersive_participantships.pending.first

    respond_to_blocking_notification_close_request(obj)
  end
end
