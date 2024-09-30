# frozen_string_literal: true

envelope json do
  json.array! @recordings do |recording|
    json.id                   recording.id
    json.thumbnail_url        recording.poster_url
    json.poster_url           recording.poster_url
    json.can_recording        can?(:share, recording)
    json.purchase_price       recording.purchase_price.to_f.to_s
    json.title                recording.always_present_title
    json.organizer do
      org = recording.organizer
      json.url                  org.relative_path
      json.public_display_name  org.public_display_name
    end
    json.numeric_rating numeric_rating_for(recording.channel)
    json.raters_count   recording.channel.raters_count
    json.views_count    recording.views_count
    json.created_at     recording.created_at.to_fs(:rfc3339)
    json.short_url      recording.short_url
    json.obtained       can?(:see_recording, recording)
    json.owner          recording.organizer == current_user
    json.free           recording.free?

    if can?(:see_recording, recording)
      json.url recording.url
    else
      json.url recording.preview_url
    end
  end
end
