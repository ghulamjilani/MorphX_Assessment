# frozen_string_literal: true

json.models do
  json.array! @replays do |replay|
    json.extract! replay, :id, :show_on_profile, :size, :status, :only_ppv, :only_subscription, :blocked, :block_reason
    json.duration replay.actual_duration
    json.title replay.always_present_title
    json.description replay.always_present_description
    json.presenter_name replay.organizer&.public_display_name
    json.views_count replay.views_count
    json.start_at replay.session&.start_at&.to_fs(:rfc3339)
    json.poster_url replay.poster_url
    json.url replay.url
    json.original_url replay.original_url
    json.price replay.session&.recorded_purchase_price
    json.private replay.session&.private?
    json.published replay.published?
    json.processing replay.processing?
    json.done replay.status == 'done'
    json.allow_chat replay.session&.allow_chat
    json.session_id replay.session&.id
    json.rating replay.rating
    if can?(:share, replay.session)
      json.share_url replay.session.preview_share_relative_path(vod_id: replay.id)
    else
      json.share_url nil
    end
    json.creator_revenue replay.organizer.revenue_percent
    json.immerss_revenue 100 - replay.organizer.revenue_percent
    json.list_id replay.list_ids.first

    json.frame_position replay.video_image&.frame_position || 0
    json.source_type replay.video_image&.source_type || 0

    json.absolute_url replay.absolute_path
    if replay.video_image
      if replay.video_image&.source_type&.zero?
        json.uploaded_poster_url replay.video_image&.image&.url
      elsif replay.video_image&.source_type == 1
        json.uploaded_poster_url replay.poster_url
        json.timeline_poster_url replay.video_image&.image&.url
      end
    else
      json.uploaded_poster_url replay.poster_url
    end
  end
end
json.limit @limit
json.offset @offset
json.total @total
