# frozen_string_literal: true

json.cache! model, expires_in: 1.day do
  json.id                                                 model.id
  json.duration                                           model.actual_duration
  json.filename                                           model.filename
  json.room_id                                            model.room_id
  json.channel_id                                         model.channel.id
  json.user_id                                            model.user_id
  json.status                                             model.status
  json.show_on_profile                                    model.show_on_profile
  json.preview_filename                                   model.preview_filename
  json.featured                                           model.featured
  json.short_url                                          model.short_url
  json.fake                                               model.fake
  json.show_on_home                                       model.show_on_home
  json.shares_count                                       model.shares_count
  json.deleted_at                                         model.deleted_at
  json.referral_short_url                                 model.referral_short_url
  json.promo_start                                        model.promo_start
  json.promo_end                                          model.promo_end
  json.promo_weight                                       model.promo_weight
  json.original_name                                      model.original_name
  json.s3_root                                            model.s3_root
  json.crop_seconds                                       model.crop_seconds
  json.hls_preview                                        model.hls_preview
  json.main_image_number                                  model.main_image_number
  json.title                                              model.title
  json.always_present_title                               model.always_present_title
  json.transcoding_uptime_id                              model.transcoding_uptime_id
  json.width                                              model.width
  json.height                                             model.height
  json.published                                          model.published
  json.description                                        model.description
  json.solr_updated_at                                    model.solr_updated_at
  json.old_id                                             model.old_id
  json.tag_list                                           model.tag_list
  json.poster_url                                         model.poster_url
  json.relative_path                                      model.relative_path
  json.views_count                                        model.views_count
  json.unique_views_count                                 model.unique_views_count
  json.popularity                                         model.session&.average&.avg || 0
  json.raters_count                                       model.raters_count
  json.created_at                                         model.created_at.utc.to_fs(:rfc3339)
  json.updated_at                                         model.updated_at.utc.to_fs(:rfc3339)
  json.rating                                             numeric_rating_for(model.session)
  json.only_ppv                                           model.only_ppv
  json.only_subscription                                  model.only_subscription
end

if current_ability.can?(:see_full_version_video, model.session)
  json.hls_main   model.hls_main
  json.url        model.url
else
  json.hls_main   nil
  json.url        model.preview_url
end
