# frozen_string_literal: true

class SessionJobs::StopNoPresenterSession < ApplicationJob
  def perform(room_id)
    if (room = Room.find_by(id: room_id))
      webrtcservice_room = room.abstract_session.webrtcservice_room

      return unless room.webrtcservice? && webrtcservice_room.present?

      webrtcservice_control = Control::WebrtcserviceRoom.new(webrtcservice_room)
      return if webrtcservice_control.presenter_connected?

      participants_connected = webrtcservice_control.participants.filter { |participant| participant[:status] == 'connected' }
      debug_logger('connected room participants', participants_connected)

      Control::Room.new(room).stop
      room.abstract_session.update_columns(stop_reason: 'wait_for_presenter_time_expired')
    end
  end
end
