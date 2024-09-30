# frozen_string_literal: true

envelope json do
  json.array! @videos do |video|
    session = video.session
    channel = session.channel
    json.id                       video.id
    json.title                    video.always_present_title
    json.poster_url               video.poster_url
    if can?(:see_full_version_video, session)
      json.url video.url
    else
      json.url video.preview_url
    end
    json.can_share                can?(:share, session)
    json.recorded_free            session.recorded_free?
    json.recorded_purchase_price  session.recorded_purchase_price.to_f.to_s
    json.organizer do
      org = video.user
      json.url                  org.relative_path
      json.public_display_name  org.public_display_name
    end

    json.owner session.organizer == current_user
    json.numeric_rating numeric_rating_for(session)
    json.raters_count channel.raters_count
    json.views_count session.views_count
    json.start_at session.start_at.to_fs(:rfc3339)
    json.obtained can?(:access_replay_as_subscriber, session) || can?(:opt_out_as_recorded_member, session)
    json.short_url video.short_url
    json.channel_title channel.title
  end
end
