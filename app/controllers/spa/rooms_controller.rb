# frozen_string_literal: true

module Spa
  class RoomsController < Spa::ApplicationController
    def show
      redirect_to root_path, flash: { error: 'This room is unavailable' } unless valid_room_request?
    end

    def join_interactive_by_token
      render :show
    end

    private

    def room
      @room ||= Room.find(params[:id])
    end

    def valid_room_request?
      room.present? && current_ability.can?(:participate, room.abstract_session)
    end
  end
end
