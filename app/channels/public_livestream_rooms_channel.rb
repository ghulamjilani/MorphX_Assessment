# frozen_string_literal: true

class PublicLivestreamRoomsChannel < ApplicationCable::Channel
  EVENTS = {
    brb: 'be_right_back enabled. Should disable participant video and audio. Data: {}',
    'brb-off': 'be_right_back disabled. Should enable participant video and audio. Data: {}',
    'join-all': 'Triggers player start for all livestreamers. Data: {livestream_up: @stream_state.eql?("up"), token: '', url: stream_url}',
    'enable-chat': 'allow_chat attribute changed for session. Data: { users: "all", session_id: self.id }',
    'disable-chat': 'allow_chat attribute changed for session. Data: { users: "all", session_id: self.id }',
    'enable-list': 'List enabled. Data: { users: "all", list_id: list_id }',
    'disable-list': 'List disabled. Data: { users: "all", list_id: "all" }',
    'livestream-up': 'Notifies about stream status change. Data: { active: room.active?, transcoder_status: transcoder_status, stream_url: stream_url }',
    'livestream-down': 'Notifies about stream status change. Data: { active: room.active?, transcoder_status: transcoder_status, stream_url: stream_url }',
    'livestream-starting': 'Notifies about stream status change. Data: { active: room.active?, transcoder_status: transcoder_status, stream_url: stream_url }',
    'livestream-off': 'Notifies about stream status change. Data: { active: room.active?, transcoder_status: transcoder_status, stream_url: stream_url }',
    'livestream-ended': 'Room status changed to closed. Livestream ended. Data: {}',
    member_subscribed: 'sent when new subscriber subscribes to channel. Data: user.id/uid',
    member_unsubscribed: 'sent when websocket connection to channel breaks. Data: user.id/uid',
    active_members: 'sent every time user subscribes/unsubscribes to this channel. Data: user_ids',
    rating_updated: 'Room rating updated. Data: {rating: rating}',
    livestream_members_count: 'Session watchers count constantly sent by cron. Data: {count: count}',
    total_participants_count_updated: 'Session participants count updated. Data: {count: session.total_participants_count, session_id: session_id}',
    product_scanned: 'New product scanned by upc. Data: { users: "all", product: product, list: list }',
    room_updated: 'Room updated. Data: { start_at: actual_start_at, end_at: actual_end_at, time_left: actual_end_at - Time.now, server_time: Time.now.utc.to_i * 1000, session_start_at: as.start_at}'
  }.freeze

  def subscribed
    stream_from 'public_livestream_rooms_channel'

    if (room = Room.find_by(id: params[:data]))
      stream_for room

      stream_from "#{channel_prefix}#{uid}" # used to identify active users connections
      PublicLivestreamRoomsChannel.broadcast_to room, event: 'member_subscribed', data: uid
      PublicLivestreamRoomsChannel.broadcast_to room, event: 'active_members', data: active_users_ids
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    if (room = Room.find_by(id: params[:data]))
      PublicLivestreamRoomsChannel.broadcast_to room, event: 'member_unsubscribed', data: uid
      PublicLivestreamRoomsChannel.broadcast_to room, event: 'active_members', data: active_users_ids
    end
  end
end
