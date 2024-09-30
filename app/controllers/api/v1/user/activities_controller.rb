# frozen_string_literal: true

class Api::V1::User::ActivitiesController < Api::V1::User::ApplicationController
  def index
    query = current_user.activities_made

    if params[:date_from] && params[:date_to]
      query = query.where(updated_at: params[:date_from]..params[:date_to])
    elsif params[:date_from]
      query = query.where('updated_at >= ?', params[:date_from])
    elsif params[:date_to]
      query = query.where('updated_at <= ?', params[:date_to])
    end

    query = query.where(trackable_type: params[:trackable_type].underscore.classify) if params[:trackable_type]

    @count = query.count

    order_by = %w[created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'updated_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
    @activities = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
  end

  def show
    @activity = current_user.activities_made.find(params[:id])
    raise Mongoid::Errors::DocumentNotFound.new(Log::Activity, params[:id]) unless @activity

    unless @activity.trackable
      (raise ActiveRecord::RecordNotFound,
             "#{@activity.trackable_type} #{@activity.trackable_id} is not available")
    end
  end

  def destroy
    query = current_user.activities_made
    ids = []
    if params[:id].present?
      query = query.where(:_id.in => params[:id])
      ids = query.pluck(:id).map(&:to_s)
      query.delete_all
    elsif params[:date_from].present? && params[:date_to].present?
      query = query.where(updated_at: params[:date_from]..params[:date_to])
      ids = query.pluck(:id).map(&:to_s)
      query.delete_all
    end
    render_json 200, ids
  end

  def destroy_all
    current_user.activities_made.delete_all
    head :ok
  end
end
