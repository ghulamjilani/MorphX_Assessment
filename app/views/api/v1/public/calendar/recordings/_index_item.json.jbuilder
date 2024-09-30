# frozen_string_literal: true

json.cache! ['app/views/api/v1/public/calendar/recordings/_index_item', recording], expires_in: 1.day do
  json.recording do
    json.partial! 'recording', recording: recording
  end
  json.user do
    json.partial! 'api/v1/public/calendar/users/user', user: recording.organizer
  end
end
