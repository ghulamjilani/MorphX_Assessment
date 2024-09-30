# frozen_string_literal: true

json.id                                      session.id
json.channel_id                              session.channel_id
json.presenter_id                            session.presenter_id
json.adult                                   session.adult
json.age_restrictions                        session.age_restrictions
json.allow_chat                              session.allow_chat
json.autostart                               session.autostart
json.cancelled_at                            session.cancelled_at&.utc&.to_fs(:rfc3339)
json.duration                                session.duration
json.end_at                                  session.end_at&.utc&.to_fs(:rfc3339)
json.immersive_free                          session.immersive_free?
json.immersive_purchase_price                session.immersive_purchase_price
json.line_slots                              session.line_slots_left
json.livestream_free                         session.livestream_free?
json.livestream_purchase_price               session.livestream_purchase_price
json.max_number_of_immersive_participants    session.max_number_of_immersive_participants
json.only_ppv                                session.only_ppv
json.only_subscription                       session.only_subscription
json.private                                 session.private
json.record                                  session.do_record?
json.recorded_free                           session.recorded_free?
json.recorded_purchase_price                 session.recorded_purchase_price
json.service_type                            session.service_type
json.start_at                                session.start_at&.utc&.to_fs(:rfc3339)
json.start_now                               session.start_now
json.title                                   session.title
json.always_present_title                    session.always_present_title
json.always_present_description              session.always_present_description
json.url                                     session.persisted? ? session.absolute_path : nil
json.relative_path                           session.persisted? ? session.relative_path : nil
json.webrtcservice_channel_id                       session.webrtcservice_channel_id
json.pre_time                                session.pre_time.to_i
json.recording_layout                        session.recording_layout
json.views_count                             session.views_count
json.unique_views_count                      session.unique_views_count
json.small_cover_url                         session.small_cover_url

json.polls do
  json.array! session.polls.order(created_at: :asc) do |poll|
    json.partial! 'api/v1/user/poll/polls/poll_short', poll: poll
  end
end
