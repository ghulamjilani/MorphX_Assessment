# frozen_string_literal: true

json.cache! ['app/views/api/v1/public/sessions/_session_short', model], expires_in: 1.day do
  json.id                                                 model.id
  json.age_restrictions                                   model.age_restrictions
  json.channel_id                                         model.channel_id
  json.presenter_id                                       model.presenter_id
  json.duration                                           model.duration
  json.start_at                                           model.start_at&.utc&.to_fs(:rfc3339)
  json.end_at                                             model.end_at&.utc&.to_fs(:rfc3339)
  json.immersive_type                                     model.immersive_type
  json.title                                              model.title
  json.cancelled_at                                       model.cancelled_at
  json.status                                             model.status
  json.stopped_at                                         model.stopped_at
  json.pre_time                                           model.pre_time
  json.description                                        model.description
  json.donations_goal                                     model.donations_goal
  json.start_now                                          model.start_now
  json.autostart                                          model.autostart
  json.service_type                                       model.service_type
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
  json.new_star_rating                                    raw new_star_rating(numeric_rating_for(model))
  json.rating                                             numeric_rating_for(model)
  json.raters_count                                       model.raters_count
  json.channel_image_preview_url                          model.channel.image_preview_url
  json.popularity                                         model.average&.avg || 0
  json.max_number_of_immersive_participants               model.max_number_of_immersive_participants
  json.created_at                                         model.created_at.utc.to_fs(:rfc3339)
  json.updated_at                                         model.updated_at.utc.to_fs(:rfc3339)
  json.absolute_path                                      model.absolute_path
  json.room_id                                            model.room&.id
  json.views_count                                        model.views_count
  json.unique_views_count                                 model.unique_views_count
  json.only_ppv                                           model.only_ppv
  json.only_subscription                                  model.only_subscription
end

json.watchers_count                                     model.room&.watchers_count || 0
json.url_params                                         url_attrs(model)
json.opt_out_as_recorded_member                         current_ability.can?(:opt_out_as_recorded_member, model)
json.access_replay_as_subscriber                        current_ability.can?(:access_replay_as_subscriber, model)
json.join_as_presenter                                  current_ability.can?(:join_as_presenter, model)
json.join_as_participant                                current_ability.can?(:join_as_participant, model)
json.join_as_livestreamer                               current_ability.can?(:join_as_livestreamer, model)
json.access_as_subscriber                               current_ability.can?(:access_as_subscriber, model)
json.can_share                                          current_ability.can?(:share, model)
