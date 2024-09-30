# frozen_string_literal: true

json.cache! model, expires_in: 1.day do
  json.id                                                 model.id
  json.channel_id                                         model.channel_id
  json.presenter_id                                       model.presenter_id
  json.duration                                           model.duration
  json.start_at                                           model.start_at&.utc&.to_fs(:rfc3339)
  json.end_at                                             model.end_at&.utc&.to_fs(:rfc3339)
  json.immersive_type                                     model.immersive_type
  json.title                                              model.title
  json.pre_time                                           model.pre_time.to_i
  json.description                                        model.description
  json.service_type                                       model.service_type
  json.service_status                                     model.service_status
  json.device_type                                        model.device_type
  json.allow_chat                                         model.allow_chat
  json.livestream_free                                    model.livestream_free
  json.immersive_free                                     model.immersive_free
  json.recorded_free                                      model.recorded_free
  json.livestream_purchase_price                          model.livestream_purchase_price
  json.immersive_purchase_price                           model.immersive_purchase_price
  json.recorded_purchase_price                            model.recorded_purchase_price
  json.small_cover_url                                    model.small_cover_url
  json.line_slots_left                                    model.line_slots_left
  json.relative_path                                      model.relative_path
  json.preview_share_relative_path                        model.preview_share_relative_path
  json.always_present_title                               model.always_present_title
  json.always_present_description                         model.always_present_description
  json.max_number_of_immersive_participants               model.max_number_of_immersive_participants
  json.webrtcservice_channel_id                                  model.webrtcservice_channel_id
  json.views_count                                        model.views_count
  json.unique_views_count                                 model.unique_views_count
  json.created_at                                         model.created_at.utc.to_fs(:rfc3339)
end

json.channel_image_preview_url                          model.channel.image_preview_url
json.watchers_count                                     model.room&.watchers_count || 0

json.polls do
  json.array! @session.polls.order(created_at: :asc) do |poll|
    json.partial! 'api/v1/public/poll/polls/poll', poll: poll
  end
end
