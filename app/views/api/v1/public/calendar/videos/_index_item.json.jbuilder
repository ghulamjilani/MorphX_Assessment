# frozen_string_literal: true

json.cache! ['app/views/api/v1/public/calendar/videos/_index_item', video], expires_in: 1.day do
  json.video do
    json.partial! 'video', video: video
  end
  json.session do
    json.partial! 'api/v1/public/calendar/sessions/session', session: video.room.abstract_session
  end
  json.user do
    json.partial! 'api/v1/public/calendar/users/user', user: video.room.abstract_session.presenter.user
  end
end
