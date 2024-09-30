# frozen_string_literal: true

class RoomMembersChannel < ApplicationCable::Channel
  EVENTS = {}.freeze

  def subscribed
    if (room_member = RoomMember.find_by(id: params[:data]))
      room_member.update(joined: true)
      stream_for room_member
      SidekiqSystem::Schedule.remove(RoomMemberJobs::RoomMemberDisconnectedJob, room_member.id)
    end
  end

  def unsubscribed
    return unless (room_member = RoomMember.find_by(id: params[:data]))

    if room_member.kind.eql?(RoomMember::Kinds::PRESENTER)
      Control::Room.new(room_member.room).unpin_all
    else
      room_member.unpinned!
    end

    room_member.update(joined: false)
    RoomMemberJobs::RoomMemberDisconnectedJob.perform_at(30.seconds.from_now, room_member.id)
  end

  def self.subscribed_room_member_ids
    active_subscriptions.map { |subscription| subscription.match(%r{^RoomMember/(\d+)$}) }.compact.map { |m| m[1] }
  end

  def self.room_member_subscribed?(room_member_id)
    subscribed_room_member_ids.include?(room_member_id)
  end
end
