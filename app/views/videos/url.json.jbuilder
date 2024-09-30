# frozen_string_literal: true

if can?(:see_full_version_video, @session)
  json.url @video.url
else
  json.url @video.preview_url
end
json.poster_url @video.poster_url || asset_url(@session.channel.image_preview_url)

json.video_info do
  json.title            @session.title
  json.formatted_time   time_with_tz_in_chosen_format(@session.start_at)
  json.duration         @video.duration_in_minutes || @session.duration
  json.duration_seconds @video.duration            || (@session.duration.to_i * 60 * 1000)
  json.level            @session.level.to_s.capitalize
  json.description      @session.always_present_description
end

unless can?(:see_full_version_video, @session)
  json.session_price do
    json.price as_currency(@session.recorded_purchase_price)
    json.purchase_url preview_purchase_channel_session_path(@session.slug, type: ObtainTypes::PAID_VOD)
  end
end

if Session.joins(:channel).where(channels: { organization_id: current_user&.organization_id }).exists?(id: @session.id)
  json.session_price_for_presenter do
    json.price as_currency(@session.recorded_purchase_price)
  end
end

json.additional_info do
  json.user_sign_in current_user.present?
  json.free !@session.recorded_purchase_price.nil? && @session.recorded_purchase_price.zero?
end
