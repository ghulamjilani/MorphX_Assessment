# frozen_string_literal: true

envelope json do
  json.array! @sessions do |session|
    json.session do
      json.partial! '/api/v1/user/sessions/session', session: session
      json.relative_path session.relative_path
      json.opt_out_as_recorded_member                         can?(:opt_out_as_recorded_member, session)
      json.access_replay_as_subscriber                        can?(:access_replay_as_subscriber, session)
      json.join_as_presenter                                  can?(:join_as_presenter, session)
      json.join_as_participant                                can?(:join_as_participant, session)
      json.join_as_livestreamer                               can?(:join_as_livestreamer, session)
      json.access_as_subscriber                               can?(:access_as_subscriber, session)
      json.can_share                                          can?(:share, session)
    end

    json.channel do
      json.partial! '/api/v1/user/channels/channel_short', channel: session.channel
    end

    if session.zoom_meeting.present?
      json.zoom_meeting do
        json.partial! '/api/v1/user/sessions/zoom_meeting', session: session
      end
    end

    if session.room
      json.room do
        json.partial! '/api/v1/user/rooms/room', room: session.room
      end
    end

    json.presentation_info do
      json.partial! '/api/v1/user/sessions/presentation_info', session: session
    end

    json.presenter do
      json.partial! '/api/v1/user/users/user_short', user: session.organizer
    end

    json.organization do
      json.partial! '/api/v1/user/organizations/organization_short', organization: session.organization
    end

    json.role role_for_session(session)
    json.backstage session.room&.user_backstage_enabled?(current_user)
  end
end
