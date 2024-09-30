# frozen_string_literal: true

class Api::V1::Public::VideosController < Api::V1::Public::ApplicationController
  def index
    query = Video.with_new_vods.available.visible.published
                 .joins(:room).joins({ session: :channel }, :user)
                 .where.not(channels: { listed_at: nil })
                 .where(channels: { status: :approved, archived_at: nil, fake: false }, users: { fake: false })

    query = query.where(show_on_home: true) if params[:show_on_home].present?
    query = query.where(user_id: params[:user_id]) if params[:user_id].present?
    query = query.where(room_id: params[:room_id]) if params[:room_id].present?
    query = query.where(rooms: { abstract_session_id: params[:session_id] }) if params[:session_id].present?
    query = query.where(sessions: { channel_id: params[:channel_id] }) if params[:channel_id].present?

    if params[:start_at_from].present? && params[:start_at_to].present?
      query = query.where('sessions.start_at' => params[:start_at_from]..params[:start_at_to])
    elsif params[:start_at_from].present?
      query = query.where('sessions.start_at >= ?', params[:start_at_from])
    elsif params[:start_at_to].present?
      query = query.where('sessions.start_at <= ?', params[:start_at_to])
    end

    if params[:duration_from].present? && params[:duration_to].present?
      query = query.where(duration: params[:duration_from]..params[:duration_to])
    elsif params[:duration_from].present?
      query = query.where('duration >= ?', params[:duration_from])
    elsif params[:duration_to].present?
      query = query.where('duration <= ?', params[:duration_to])
    end

    @count = query.count
    if params[:order_by].present?
      order_by = %w[id duration created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
      order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
      query = query.order(Arel.sql("#{order_by} #{order}"))
    else
      query = query.order(Arel.sql('CASE WHEN ((videos.promo_weight <> 0 AND videos.promo_start IS NULL AND videos.promo_end IS NULL) OR (videos.promo_start < now() AND now() < videos.promo_end)) THEN 100 + videos.promo_weight ELSE 0 END ASC, videos.created_at DESC'))
    end

    @videos = query.limit(@limit).offset(@offset)
  end

  def show
    @video = Video.with_new_vods.available.visible.published
                  .joins(:room).joins({ session: :channel }, :user)
                  .where.not(channels: { listed_at: nil })
                  .where(channels: { status: :approved, archived_at: nil, fake: false }, users: { fake: false }).find(params[:id])

    render_json(403, 'Access denied') and return unless can?(:read, @video)
  end
end
