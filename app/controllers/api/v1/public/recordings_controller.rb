# frozen_string_literal: true

class Api::V1::Public::RecordingsController < Api::V1::Public::ApplicationController
  def index
    query = Recording.visible.available

    query = query.where(channel_id: params[:channel_id]) if params[:channel_id].present?
    query = query.where(channels: { organization_id: params[:organization_id] }) if params[:organization_id].present?

    if params[:created_at_from].present? && params[:created_at_to].present?
      query = query.where('recordings.created_at' => params[:created_at_from]..params[:created_at_to])
    elsif params[:created_at_from].present?
      query = query.where('recordings.created_at >= ?', params[:created_at_from])
    elsif params[:created_at_to].present?
      query = query.where('recordings.created_at <= ?', params[:created_at_to])
    end

    order_by = %w[id duration created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
    @count = query.count
    @recordings = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
  end

  def show
    @recording = Recording.visible.available.find(params[:id])

    render_json(403, 'Access denied') and return unless can?(:see_recording, @recording)
  end
end
