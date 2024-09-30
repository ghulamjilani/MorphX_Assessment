# frozen_string_literal: true

class Api::VideosController < Api::ApplicationController
  # curl -XGET http://localhost:3000/api_portal/channels/1/videos/ -H 'X-User-Token: 9f3f5ab404dde17472119127b52aeadb1' -H 'X-User-ID:1'
  before_action :offset_limit

  def index
    @channel = Channel.find(params[:channel_id])
    query = Video.for_channel_and_user(@channel.id, current_user.try(:id) || -1).order('sessions.start_at DESC')
    @videos = query.limit(@limit).offset(@offset)
    @count = query.count
  end

  def for_user
    query = Video.for_channel_and_user(nil, current_user.try(:id) || -1).order('sessions.start_at DESC')
    @videos = query.limit(@limit).offset(@offset)
    @count = query.count
    render :index
  end

  def for_home
    query = Video.with_new_vods.not_fake.for_home_page
                 .joins({ session: :channel }, :user).where.not(channels: { listed_at: nil })
                 .where(channels: { status: :approved, archived_at: nil, fake: false }, users: { fake: false })
                 .order(Arel.sql('CASE WHEN ((videos.promo_weight <> 0 AND videos.promo_start IS NULL AND videos.promo_end IS NULL) OR (videos.promo_start < now() AND now() < videos.promo_end)) THEN 100 + videos.promo_weight ELSE 0 END ASC, videos.created_at DESC'))
                 .limit(@limit).preload(session: [{ presenter: { user: :image } }, :channel])
    @videos = query.limit(@limit).offset(@offset)
    @count = query.count

    render :index
  end
end
