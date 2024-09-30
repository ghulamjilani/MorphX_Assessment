# frozen_string_literal: true

module RoomMemberJobs
  class RoomMemberDisconnectedJob < ApplicationJob
    sidekiq_options queue: :default

    def perform(room_member_id)
      room_member = RoomMember.find_by(id: room_member_id)

      return if room_member.blank?

      return if RoomMembersChannel.room_member_subscribed?(room_member_id)

      room_member.update(joined: false)

      room_member.room.session.remove_webrtcservice_participant(room_member)

      if room_member.guest?
        room_member.destroy
      end
    end
  end
end
