# frozen_string_literal: true

json.cache! room, expires_in: 1.day do
  json.id                          room.id
  json.status                      room.status
  json.is_screen_share_available   room.is_screen_share_available
  json.abstract_session_id         room.abstract_session_id
  json.abstract_session_type       room.abstract_session_type
  json.actual_start_at             room.actual_start_at.utc.to_fs(:rfc3339)
  json.actual_end_at               room.actual_end_at.utc.to_fs(:rfc3339)
  json.created_at                  room.created_at.utc.to_fs(:rfc3339)
  json.updated_at                  room.updated_at.utc.to_fs(:rfc3339)
end
