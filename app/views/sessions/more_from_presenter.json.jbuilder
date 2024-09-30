# frozen_string_literal: true

json.array! @replays do |replay|
  json.id replay.id
  json.title replay.always_present_title
  json.url replay.relative_path
  json.price replay.session.recorded_purchase_price.round(2)
  json.share_url replay.session.preview_share_relative_path
  json.image_url replay.poster_url || asset_url(replay.session.channel.image_preview_url)
end
