# frozen_string_literal: true

class RoomsChannel < ApplicationCable::Channel
  EVENTS = {
    disable: 'Room closed or session cancelled. Data: {room_id: room.id}',
    update: 'room.actual_start_at changed. Needed to update "Join" buttons for presenters. Data: {room_id: room.id, now: Time.now.to_i, start_at: room.actual_start_at.to_i}'
  }.freeze

  def subscribed
    stream_from 'rooms_channel'

    if (room = Room.find_by(id: params[:data]))
      stream_for room
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
