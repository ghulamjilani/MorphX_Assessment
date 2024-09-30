# frozen_string_literal: true

json.id                                                 session.id
json.channel_id                                         session.channel_id
json.presenter_id                                       session.presenter_id
json.duration                                           session.duration
json.start_at                                           session.start_at&.utc&.to_fs(:rfc3339)
json.immersive_type                                     session.immersive_type
json.title                                              session.title
json.cancelled_at                                       session.cancelled_at
json.status                                             session.status
json.stopped_at                                         session.stopped_at
json.pre_time                                           session.pre_time
json.description                                        session.description
json.donations_goal                                     session.donations_goal
json.start_now                                          session.start_now
json.autostart                                          session.autostart
json.service_type                                       session.service_type
json.device_type                                        session.device_type
json.allow_chat                                         session.allow_chat
json.ffmpegservice_account_id                                   session.ffmpegservice_account_id
json.created_at                                         session.created_at.utc.to_fs(:rfc3339)
json.updated_at                                         session.updated_at.utc.to_fs(:rfc3339)
