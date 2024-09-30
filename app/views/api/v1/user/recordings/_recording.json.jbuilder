# frozen_string_literal: true

json.id                                  recording.id
json.channel_id                          recording.channel_id
json.provider                            recording.provider
json.vid                                 recording.vid
json.title                               recording.title
json.description                         recording.description
json.url                                 recording.url
json.raw                                 recording.raw
json.purchase_price                      recording.purchase_price
json.private                             recording.private
json.hide                                recording.hide
json.shares_count                        recording.shares_count
json.short_url                           recording.short_url
json.referral_short_url                  recording.referral_short_url
json.cached_votes_total                  recording.cached_votes_total
json.cached_votes_score                  recording.cached_votes_score
json.cached_votes_up                     recording.cached_votes_up
json.cached_votes_down                   recording.cached_votes_down
json.cached_weighted_score               recording.cached_weighted_score
json.promo_start                         recording.promo_start
json.promo_end                           recording.promo_end
json.promo_weight                        recording.promo_weight
json.show_on_home                        recording.show_on_home
json.published                           recording.published
json.status                              recording.status
json.hls_main                            recording.hls_main
json.hls_preview                         recording.hls_preview
json.main_image_number                   recording.main_image_number
json.width                               recording.width
json.height                              recording.height
json.deleted_at                          recording.deleted_at
json.s3_root                             recording.s3_root
json.duration                            recording.actual_duration
json.fake                                recording.fake
json.tag_list                            recording.tag_list
json.relative_path                       recording.relative_path
json.can_share                           current_ability.can?(:share, recording)
json.is_purchased                        current_user.present? && recording.recording_members.where(participant_id: current_user.try(:participant_id)).present?
json.preview_share_relative_path         recording.preview_share_relative_path
json.always_present_title                recording.always_present_title
json.views_count                         recording.views_count
json.poster_url                          recording.poster_url
json.new_star_rating                     raw new_star_rating(numeric_rating_for(recording))
json.rating                              numeric_rating_for(recording)
json.popularity                          recording.average&.avg || 0
json.raters_count                        recording.raters_count
json.created_at                          recording.created_at.utc.to_fs(:rfc3339)
json.updated_at                          recording.updated_at.utc.to_fs(:rfc3339)
