# frozen_string_literal: true

module SessionJobs
  class StopNoPresenterNotificationJob < ApplicationJob
    def perform(room_id)
      return unless (room = Room.find_by(id: room_id))

      webrtcservice_room = room.abstract_session.webrtcservice_room || room.abstract_session.build_webrtcservice_room

      return if Control::WebrtcserviceRoom.new(webrtcservice_room).presenter_connected?

      stop_no_presenter_job = SidekiqSystem::Schedule.find(SessionJobs::StopNoPresenterSession, room_id)
      return if stop_no_presenter_job.nil?

      PresenceImmersiveRoomsChannel.broadcast_to(
        room,
        event: 'no_presenter_stop_scheduled',
        data: { stop_at: stop_no_presenter_job.at.utc.to_fs(:rfc3339) }
      )
    end
  end
end
