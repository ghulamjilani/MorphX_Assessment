# frozen_string_literal: true

class ChannelInvitedParticipantshipsController < ApplicationController
  def forcefully_close
    # TODO: Do we need blocking_notification for channel co-presenters?
    # channel = Channel.find(params[:channel_id])
    # obj = channel
    #   .channel_invited_presenterships
    #   .pending
    #   .where(presenter_id: current_user.presenter.id)
    #   .first

    respond_to_blocking_notification_close_request(nil)
  end
end
