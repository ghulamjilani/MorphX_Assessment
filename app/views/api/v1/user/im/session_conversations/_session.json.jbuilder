# frozen_string_literal: true

json.id             session.id
json.allow_chat     session.allow_chat
json.channel_id     session.channel_id
json.desription     session.desription
json.duration       session.duration
json.end_at         session.end_at.utc.to_fs(:rfc3339)
json.presenter_id   session.presenter_id
json.service_type   session.service_type
json.start_at       session.start_at.utc.to_fs(:rfc3339)
json.title          session.title
json.created_at     session.created_at.utc.to_fs(:rfc3339)
json.updated_at     session.updated_at.utc.to_fs(:rfc3339)
