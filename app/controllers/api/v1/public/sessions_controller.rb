# frozen_string_literal: true

class Api::V1::Public::SessionsController < Api::V1::Public::ApplicationController
  before_action :set_session, only: [:show]

  def index
    query = Session.is_public.not_fake.published.not_archived.not_cancelled.not_stopped
                   .joins('LEFT OUTER JOIN channels ON channels.id = sessions.channel_id')
                   .joins('LEFT OUTER JOIN presenters ON presenters.id = channels.presenter_id')
                   .joins('LEFT OUTER JOIN organizations ON organizations.id = channels.organization_id')

    %w[start_at duration].each do |param_name|
      from_name = "#{param_name}_from".to_sym
      to_name = "#{param_name}_to".to_sym
      if params[from_name].present? && params[to_name].present?
        query = query.where(param_name => params[from_name]..params[to_name])
      elsif params[from_name].present?
        query = query.where("#{param_name} >= ?", params[from_name])
      elsif params[to_name].present?
        query = query.where("#{param_name} <= ?", params[to_name])
      end
    end

    if params[:end_at_from].present?
      query = query.where(
        "(stopped_at IS NULL AND (start_at + (INTERVAL '1 minute' * duration)) >= :end_at) OR (stopped_at IS NOT NULL AND stopped_at >= :end_at)", end_at: params[:end_at_from]
      )
    end
    if params[:end_at_to].present?
      query = query.where(
        "(stopped_at IS NULL AND (start_at + (INTERVAL '1 minute' * duration)) <= :end_at) OR (stopped_at IS NOT NULL AND stopped_at <= :end_at)", end_at: params[:end_at_to]
      )
    end

    query = query.where(channel_id: params[:channel_id]) if params[:channel_id].present?
    query = query.where(presenter_id: params[:presenter_id]) if params[:presenter_id].present?
    query = query.where(channels: { organization_id: params[:organization_id] }) if params[:organization_id].present?
    if params[:owner_id].present?
      query = query.where('presenters.user_id = :owner_id OR organizations.user_id = :owner_id',
                          owner_id: params[:owner_id])
    end

    order_by = %w[start_at end_at].include?(params[:order_by]) ? params[:order_by] : 'start_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'

    @count = query.count
    @sessions = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
                     .preload(
                       quality_of_content_average: {},
                       room: {},
                       presenter: { user: %i[image user_account] },
                       channel: [:cover]
                     )
  end

  def show
    render_json(403, 'Access denied') and return unless can?(:read, @session)

    @session.log_daily_activity(:view, owner: current_user) if current_user.present?
  end

  private

  def set_session
    @session = Session.friendly.find(params[:id])
  end
end
