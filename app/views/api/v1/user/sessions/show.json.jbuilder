# frozen_string_literal: true

envelope json, (@status || 200), @session.pretty_errors.presence do
  json.session do
    json.partial! '/api/v1/user/sessions/session', session: @session
  end

  json.channel do
    json.partial! '/api/v1/user/channels/channel_short', channel: @session.channel
  end

  if @session.zoom_meeting.present?
    json.zoom_meeting do
      json.partial! 'zoom_meeting', session: @session
    end
  end

  if @session.room
    json.room do
      json.partial! '/api/v1/user/rooms/room', room: @session.room
    end
  end

  json.presentation_info do
    json.partial! '/api/v1/user/sessions/presentation_info', session: @session
  end

  json.presenter do
    json.partial! '/api/v1/user/users/user_short', user: @session.organizer
  end

  json.role role_for_session(@session)
  json.backstage @session.room.user_backstage_enabled?(current_user)
end
