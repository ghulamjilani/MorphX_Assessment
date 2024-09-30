# frozen_string_literal: true

class SessionInvitedCoPresentershipsController < ApplicationController
  def forcefully_close
    session = Session.find(params[:session_id])
    obj = session
          .session_invited_immersive_co_presenterships
          .pending
          .where(presenter_id: current_user.presenter_id)
          .first

    respond_to_blocking_notification_close_request(obj)
  end
end
