# frozen_string_literal: true

class SessionsChannel < ApplicationCable::Channel
  EVENTS = {
    'livestream-up': 'Notifies about stream status change. Data: { session_id: room.abstract_session_id, active: room.active?, transcoder_status: transcoder_status }',
    'livestream-down': 'Notifies about stream status change. Data: { session_id: room.abstract_session_id, active: room.active?, transcoder_status: transcoder_status }',
    'livestream-starting': 'Notifies about stream status change. Data: { session_id: room.abstract_session_id, active: room.active?, transcoder_status: transcoder_status }',
    'livestream-off': 'Notifies about stream status change. Data: { session_id: room.abstract_session_id, active: room.active?, transcoder_status: transcoder_status }',
    'session-started': 'Room status changed to active. Data: { session_id: session.id }',
    'session-stopped': 'Room status changed to closed. Data: { session_id: session.id }',
    'session-cancelled': 'Session cancelled. Data: { session_id: session.id }',
    total_participants_count_updated: 'Session participants count updated. Data: {count: session.total_participants_count, session_id: session_id}',
    chat_member_banned: 'Chat member banned. Data: { user_id: chat_ban.banned_id, user_type: chat_ban.banned_type, session_id: session.id, channel_id: chat_channel.id }',
    livestream_members_count: 'Count of listeners of PublicLivestreamRoomsChannel sent by cron each minute. Data: {count: count, session_id: session.id}',
    'force-refresh-live-guide': 'Forse refresh live guide when session start_at changes. Data: {}',
    new_video_published: 'Video status changed to done. Data: {video: {id: video.id, relative_path: video.relative_path}}'
  }.freeze

  def subscribed
    stream_from 'sessions_channel'
    stream_for current_user
    if (session = Session.find_by(id: params[:data]))
      stream_for session
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
