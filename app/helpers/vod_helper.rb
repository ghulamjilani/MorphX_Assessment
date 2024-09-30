# frozen_string_literal: true

module VodHelper
  include ActionView::Helpers::AssetUrlHelper

  def vod_data_attributes(video)
    # NOTE: @session here could be completely different session!
    _session = video.room.abstract_session
    data = {}
    if can?(:see_full_version_video, _session)
      data['url'] = video.url
      data['m3u8_url'] = video.url
    else
      data['url'] = video.preview_url
      data['m3u8_url'] = video.url
    end
    data['poster_url'] = video.poster_url || asset_url(_session.channel.image_preview_url)
    data['title'] = _session.title
    data['duration'] = "#{_session.duration} Minutes"

    data['level'] = _session.level.to_s.capitalize
    data['description'] = _session.always_present_description

    unless can?(:see_full_version_video, _session)
      data['obtainable_for_amount'] = as_currency(_session.recorded_purchase_price)
      data['obtain_url'] = preview_purchase_channel_session_path(_session.slug, type: ObtainTypes::PAID_VOD)
    end
    data['id'] = video.id
    data['lists'] = video.lists.includes(:products).to_json

    # if Session.joins(:channel).where(channels: {organization_id: (current_user.organization_id rescue nil)}).where(id: _session.id).exists?
    #  data[:sessionPriceForPresenterPrice] = as_currency(_session.recorded_purchase_price)
    # end

    data
  end

  def replay_dashboard_attributes(session)
    replays = session.records.available.map do |replay|
      {
        id: replay.id,
        url: replay.url,
        status: replay.status,
        available: replay.available?,
        thumbnail_url: (replay.poster_url || asset_url(session.channel.image_preview_url)),
        show_on_profile: replay.show_on_profile,
        preview_share_relative_path: session.preview_share_relative_path(VIDEO_ID_FOR_SHARING => replay.try(:id))
      }
    end
    date_format = begin
      current_user.am_format? ? '%^b %d %Y, %l:%M %p' : '%^b %d %Y, %k:%M'
    rescue StandardError
      '%^b %d %Y, %l:%M %p'
    end
    {
      id: session.id,
      title: session.records.available.first.always_present_title,
      private: session.private,
      views_count: session.views_count,
      recorded_purchase_price: session.recorded_purchase_price.to_f,
      rating: (session.channel.average ? session.channel.average.avg : 0),
      list_id: replays.first&.list_ids,
      video_data_and_duration: "#{time_with_tz_in_chosen_format(session.start_at || room.actual_start_at)} #{formatted_session_duration(session.duration)}",
      date: (session.start_at || room.actual_start_at).strftime(date_format),
      duration: formatted_session_duration(session.duration),
      replays: replays,
      is_owner: session.organizer == current_user || session.channel.organizer == current_user,
      relative_path: session.relative_path
    }
  end
end
