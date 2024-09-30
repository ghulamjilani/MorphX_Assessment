# frozen_string_literal: true

is_purchased = current_user.present? && model.recording_members.exists?(participant_id: current_user.try(:participant_id))

json.cache! ['app/views/api/v1/public/recording/_recording_short', model], expires_in: 1.day do
  json.id                                  model.id
  json.channel_id                          model.channel_id
  json.provider                            model.provider
  json.vid                                 model.vid
  json.title                               model.title
  json.description                         model.description
  json.raw                                 model.raw
  json.purchase_price                      model.purchase_price
  json.private                             model.private
  json.hide                                model.hide
  json.shares_count                        model.shares_count
  json.short_url                           model.short_url
  json.referral_short_url                  model.referral_short_url
  json.cached_votes_total                  model.cached_votes_total
  json.cached_votes_score                  model.cached_votes_score
  json.cached_votes_up                     model.cached_votes_up
  json.cached_votes_down                   model.cached_votes_down
  json.cached_weighted_score               model.cached_weighted_score
  json.promo_start                         model.promo_start
  json.promo_end                           model.promo_end
  json.promo_weight                        model.promo_weight
  json.show_on_home                        model.show_on_home
  json.published                           model.published
  json.status                              model.status
  json.hls_preview                         model.hls_preview
  json.main_image_number                   model.main_image_number
  json.width                               model.width
  json.height                              model.height
  json.deleted_at                          model.deleted_at
  json.s3_root                             model.s3_root
  json.duration                            model.duration
  json.fake                                model.fake
  json.tag_list                            model.tag_list
  json.relative_path                       model.relative_path
  json.preview_share_relative_path         model.preview_share_relative_path
  json.always_present_title                model.always_present_title
  json.views_count                         model.views_count
  json.unique_views_count                  model.unique_views_count
  json.poster_url                          model.poster_url
  json.new_star_rating                     raw new_star_rating(numeric_rating_for(model))
  json.rating                              numeric_rating_for(model)
  json.popularity                          model.average&.avg || 0
  json.raters_count                        model.raters_count
  json.created_at                          model.created_at.utc.to_fs(:rfc3339)
  json.updated_at                          model.updated_at.utc.to_fs(:rfc3339)
  json.free                                model.free?
  json.only_ppv                            model.only_ppv
  json.only_subscription                   model.only_subscription
end

if current_ability.can?(:see_recording, model)
  json.hls_main                            model.hls_main
  json.url                                 model.url
else
  json.hls_main                            nil
  json.url                                 model.preview_url
end

json.can_share                           current_ability.can?(:share, model)
json.is_purchased                        is_purchased
