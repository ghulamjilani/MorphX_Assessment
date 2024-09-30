# frozen_string_literal: true

class PresenceImmersiveRoomsChannel < ApplicationCable::Channel
  EVENTS = {
    'backstage-changed': 'Backstage changed for some room members/for room. Data: data: { room_members: [room_member.id], users: [room_member.abstract_user_id], status: "enabled", all: true}',
    'ban-kick': 'Room member banned. Data: { room_member_id: id, ban_reason: ban_reason&.name }',
    'brb-off': 'be_right_back disabled. Should enable participant video and audio. Data: {}',
    'client-media-player-start': 'Starts media player, triggered by by presenter in lobby via js. Data: {}',
    'disable-chat': 'allow_chat attribute changed for session. Data: { users: "all", session_id: self.id }',
    'disable-list': 'List disabled. Data: { users: "all", list_id: "all" }',
    'enable-chat': 'allow_chat attribute changed for session. Data: { users: "all", session_id: self.id }',
    'enable-list': 'List enabled. Data: { users: "all", list_id: list_id }',
    'mic-changed': 'Room member muted/unmuted. Data: { room_members: [room_member.id], status: "disabled", all: true }',
    'new-question': 'No usage found',
    'screen-share-ability-changed': 'Room screen share ability changed. Data: {is_screen_share_available: room.is_screen_share_available}',
    'session-ended': 'Room status changed to closed. Data: {}',
    'unban': 'Room member unbanned. Data: { room_member_id: id }',
    'video-changed': 'Room member video enabled/disabled. Data: { room_members: [room_member.id], status: "disabled", all: false }',
    active_members: 'sent every time user subscribes/unsubscribes to this channel. Data: user_ids',
    allow_control: 'Allows control for co_presenter. Currently co_presenter role is unavailable. Data: { room_member_id: room_member.id }',
    brb: 'be_right_back enabled. Should disable participant video and audio. Data: {}',
    disable_control: 'Disable control for co_presenter. Currently co_presenter role is unavailable. Data: { room_member_id: room_member.id }',
    join: 'instructs participants to join room. Data: {users: user_ids}',
    livestream_members_count: 'Session watchers count constantly sent by cron. Data: {count: count}',
    member_subscribed: 'sent when new subscriber subscribes to channel. Data: user.id/uid',
    member_unsubscribed: 'sent when websocket connection to channel breaks. Data: user.id/uid',
    new_member: 'New session participation created. Data: { id: user.id }',
    no_presenter_stop_scheduled: 'Session stop scheduled in 5 minutes because of presenter absence',
    pinned_users: 'interactive room pins changed. Data: { pinned_members: room_members_pinned.pluck(:id) }',
    presenter_joined: 'Presenter returned to session, absence autostop cancelled',
    product_scanned: 'New product scanned by upc. Data: { users: "all", product: product, list: list }',
    remote_control: 'Remote control for user. Buttons: mute, unmute, start_video, stop_video, full_screen. Data: {button: "mute", user_id: user.id}',
    room_active: 'Room status changed to active. Data: {}',
    room_updated: 'Room updated. Data: { start_at: actual_start_at, end_at:   actual_end_at, time_left: actual_end_at - Time.now, server_time: Time.now.utc.to_i * 1000, session_start_at: as.start_at}',
    set_presenter_mode: 'No usage found'
  }.freeze

  def subscribed
    stream_from 'presence_immersive_rooms_channel'

    if (room = Room.find_by(id: params[:data]))
      stream_for room

      stream_from "#{channel_prefix}#{uid}" # used to identify active users connections
      PresenceImmersiveRoomsChannel.broadcast_to room, event: 'member_subscribed', data: uid
      PresenceImmersiveRoomsChannel.broadcast_to room, event: 'active_members', data: active_users_ids
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    if (room = Room.find_by(id: params[:data]))
      PresenceImmersiveRoomsChannel.broadcast_to room, event: 'member_unsubscribed', data: uid
      PresenceImmersiveRoomsChannel.broadcast_to room, event: 'active_members', data: active_users_ids
    end
  end
end
