# frozen_string_literal: true

envelope json do
  json.videos do
    json.array! @videos do |video|
      json.video do
        json.partial! 'video_short', model: video
      end
      json.room do
        json.partial! 'api/v1/public/rooms/room', model: video.room
      end
      json.abstract_session do
        json.partial! 'api/v1/public/sessions/session_short', model: video.room.abstract_session
      end
      json.presenter do
        json.partial! 'api/v1/public/presenters/presenter_short', model: video.room.abstract_session.presenter
      end
      json.presenter_user do
        json.partial! 'api/v1/public/users/user_short', model: video.room.abstract_session.presenter.user
      end
      json.organizer do
        json.partial! 'api/v1/public/users/user_short', model: video.user
      end
    end
  end
end
