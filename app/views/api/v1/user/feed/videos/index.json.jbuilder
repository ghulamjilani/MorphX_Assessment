# frozen_string_literal: true

envelope json do
  json.array! @videos do |video|
    session = video.session
    json.video do
      json.partial! '/api/v1/user/videos/video', video: video
      json.total_views_count video.total_views_count
      json.relative_path video.relative_path
      if can?(:see_full_version_video, session)
        json.url video.url
      end
      json.owner session.organizer == current_user
      json.obtained can?(:access_replay_as_subscriber, session) || can?(:opt_out_as_recorded_member, session)
    end

    json.user do
      json.partial! '/api/v1/user/users/user_short', user: video.user
    end

    json.session do
      json.partial! '/api/v1/user/sessions/session', session: session

      json.can_share                               can?(:share, session)
      json.views_count                             session.views_count
      json.numeric_rating numeric_rating_for(session)
      json.opt_out_as_recorded_member                         can?(:opt_out_as_recorded_member, session)
      json.access_replay_as_subscriber                        can?(:access_replay_as_subscriber, session)
    end

    json.channel do
      json.partial! '/api/v1/user/channels/channel_short', channel: session.channel

      json.raters_count session.channel.raters_count
    end

    json.organization do
      json.partial! '/api/v1/user/organizations/organization_short', organization: session.organization
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

    json.role role_for_session(session)
  end
end
