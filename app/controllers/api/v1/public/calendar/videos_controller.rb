# frozen_string_literal: true

class Api::V1::Public::Calendar::VideosController < Api::V1::Public::Calendar::ApplicationController
  def index
    query = Video.available.visible.not_fake.published.joins(:room).joins(:session)

    query = query.where(sessions: { channel_id: params[:channel_id] }) if params[:channel_id].present?

    if params[:start_at_from].present? && params[:start_at_to].present?
      query = query.where('sessions.start_at' => params[:start_at_from]..params[:start_at_to])
    elsif params[:start_at_from].present?
      query = query.where('sessions.start_at >= ?', params[:start_at_from])
    elsif params[:start_at_to].present?
      query = query.where('sessions.start_at <= ?', params[:start_at_to])
    end

    if params[:end_at_from].present?
      query = query.where("(sessions.start_at + (INTERVAL '1 minute' * sessions.duration)) >= ?",
                          params[:end_at_from])
    end
    if params[:end_at_to].present?
      query = query.where("(sessions.start_at + (INTERVAL '1 minute' * sessions.duration)) <= ?",
                          params[:end_at_to])
    end

    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
    @videos = query.order("sessions.start_at #{order}").limit(@limit).offset(@offset)
                   .preload([{ room: { abstract_session: { presenter: [:user] } } }, :session])
  end
end
