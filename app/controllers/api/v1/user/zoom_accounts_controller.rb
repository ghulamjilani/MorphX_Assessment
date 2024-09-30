# frozen_string_literal: true

class Api::V1::User::ZoomAccountsController < Api::V1::User::ApplicationController
  def show
    @identity = current_user.zoom_identity
    if @identity
      sender = Sender::ZoomLib.new(identity: @identity)
      @zoom_user = sender.user
    end
  end
end
