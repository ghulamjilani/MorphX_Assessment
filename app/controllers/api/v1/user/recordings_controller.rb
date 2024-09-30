# frozen_string_literal: true

class Api::V1::User::RecordingsController < Api::V1::ApplicationController
  before_action :set_recording, only: [:show]

  def index
    query = Recording.not_deleted.joins(:channel)

    if recordings_type == :purchased
      query = query.joins(recording_members: :participant).where(participants: { user_id: current_user.id })
    else
      owned_channel_ids = current_user.owned_channels.pluck(:id)
      query = query.where(channels: { id: owned_channel_ids })
    end

    query = query.where(channel_id: params[:channel_id]) if params[:channel_id].present?

    @count = query.count

    order_by = %w[id created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
    @recordings = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
  end

  def show
    render_json(401, 'You cannot access this recording') and return if cannot?(:see_recording, @recording)

    @recording.log_daily_activity(:view, owner: current_user)
  end

  private

  def set_recording
    @recording = Recording.find(params[:id])
  end

  def recordings_type
    @recordings_type ||= if %w[uploaded
                               purchased].include?(params[:recordings_type])
                           params[:recordings_type].to_sym
                         else
                           :uploaded
                         end
  end
end
