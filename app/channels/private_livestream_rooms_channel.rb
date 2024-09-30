# frozen_string_literal: true

class PrivateLivestreamRoomsChannel < ApplicationCable::Channel
  EVENTS = {
    'join-all': 'Triggers player start for all livestreamers. Data: {livestream_up: @stream_state.eql?("up"), token: '', url: stream_url}',
    'join-member': 'Triggers player start for specific livestreamer. Data: data = { livestream_up: wa&.stream_up?, user_id: user_id, url: url }',
    'livestream-up': 'Notifies about stream status change. Data: { active: room.active?, transcoder_status: transcoder_status, stream_url: stream_url }',
    'livestream-down': 'Notifies about stream status change. Data: { active: room.active?, transcoder_status: transcoder_status, stream_url: stream_url }',
    'livestream-starting': 'Notifies about stream status change. Data: { active: room.active?, transcoder_status: transcoder_status, stream_url: stream_url }',
    'livestream-off': 'Notifies about stream status change. Data: { active: room.active?, transcoder_status: transcoder_status, stream_url: stream_url }',
    'livestream-ended': 'Room status changed to closed. Livestream ended. Data: {}',
    livestream_members_count: 'Session watchers count constantly sent by cron. Data: {count: count}',
    online_users: 'Ids of active channel subscribers constantly sent by cron. Data: [{id: 1}, {id: 2}]',
    total_participants_count_updated: 'Session participants count updated. Data: {count: session.total_participants_count, session_id: session_id}',
    'enable-poll': 'Poll enabled for session. Data: { users: "all", poll_id: poll_id }',
    'disable-poll': 'Poll disabled for session. Data: { users: "all", poll_id: "all" }',
    'add-poll': 'Poll added. Data: { users: "all", poll_data: data }',
    'vote-poll': 'Poll voted. Data: { users: "all", poll_data: data }',
    'enable-list': 'List enabled. Data: { users: "all", list_id: list_id }',
    'disable-list': 'List disabled. Data: { users: "all", list_id: "all" }',
    product_scanned: 'New product scanned by upc. Data: { users: "all", product: product, list: list }',
    'screen-share-ability-changed': 'Room screen share ability changed. Data: {is_screen_share_available: room.is_screen_share_available}',
    room_updated: 'Room updated. Data: { start_at: actual_start_at, end_at:   actual_end_at, time_left: actual_end_at - Time.now, server_time: Time.now.utc.to_i * 1000, session_start_at: as.start_at}',
    new_member: 'New session participation created. Data: { id: user.id }',
    'enable-chat': 'allow_chat attribute changed for session. Data: { users: "all", session_id: self.id }',
    'disable-chat': 'allow_chat attribute changed for session. Data: { users: "all", session_id: self.id }',
    brb: 'be_right_back enabled. Should disable participant video and audio. Data: {}',
    'brb-off': 'be_right_back disabled. Should enable participant video and audio. Data: {}',
    rating_updated: 'Room rating updated. Data: {rating: rating}'
  }.freeze

  def subscribed
    if (room = Room.find_by(id: params[:data]))
      stream_for room
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
