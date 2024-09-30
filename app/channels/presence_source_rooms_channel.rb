# frozen_string_literal: true

class PresenceSourceRoomsChannel < ApplicationCable::Channel
  after_subscribe :broadcast_member_subscribed
  after_unsubscribe :broadcast_member_unsubscribed

  EVENTS = {
    join: 'instructs room participants to join. Data: {users: user_ids}',
    immersive_participantship_status_changed: 'sent when status of invited immersive participantship changes. Data: { status: status, user_id: participant.user_id }',
    member_subscribed: 'sent when new subscriber subscribes to channel',
    member_unsubscribed: 'sent when websocket connection to channel breaks',
    active_members: 'sent every time user subscribes/unsubscribes to this channel'
  }.freeze

  def subscribed
    stream_from 'presence_source_rooms_channel'

    if (room = Room.find_by(id: params[:data]))
      stream_for room

      stream_from "#{channel_prefix}#{uid}" # used to identify active users connections
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def broadcast_member_subscribed
    if (room = Room.find_by(id: params[:data]))
      PresenceSourceRoomsChannel.broadcast_to room, event: 'member_subscribed', data: uid
      PresenceSourceRoomsChannel.broadcast_to room, event: 'active_members', data: active_users_ids
    end
  end

  def broadcast_member_unsubscribed
    if (room = Room.find_by(id: params[:data]))
      PresenceSourceRoomsChannel.broadcast_to room, event: 'member_unsubscribed', data: uid
      PresenceSourceRoomsChannel.broadcast_to room, event: 'active_members', data: active_users_ids
    end
  end
end
