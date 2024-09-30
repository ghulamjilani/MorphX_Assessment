# frozen_string_literal: true

json.cache! ['app/views/api/v1/public/calendar/sessions/_session', session], expires_in: 1.day do
  json.id                      session.id
  json.channel_id              session.channel_id
  json.start_at                session.start_at&.utc&.to_fs(:rfc3339)
  json.end_at                  session.end_at&.utc&.to_fs(:rfc3339)
  json.title                   session.title
  json.description             session.description
end
