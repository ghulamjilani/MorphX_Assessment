# frozen_string_literal: true

module Webrtcservice
  module RoomJobs
    class RemoveParticipantJob < ApplicationJob
      def perform(room_member_id)
        room_member = RoomMember.find(room_member_id)

        webrtcservice_room = room_member.session.webrtcservice_room
        return if webrtcservice_room.blank?

        identity = Webrtcservice::Video::Participant.new(room_member: room_member).identity
        Sender::Webrtcservice::Video.client.disconnect_room_participant(webrtcservice_room.sid, identity, { expected_status: [200, 202, 404] })
      rescue StandardError => e
        Airbrake.notify(e, { message: 'Failed to remove room participant' })
      end
    end
  end
end
