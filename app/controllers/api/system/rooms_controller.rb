# frozen_string_literal: true

class Api::System::RoomsController < Api::System::ApplicationController
  before_action :http_basic_authenticate
  before_action :load_room, only: [:status_changed]

  def status_changed
    @room.cable_status_notifications
    head :ok
  end

  private

  def load_room
    @room = Room.find_by(id: params[:id])
  end
end
