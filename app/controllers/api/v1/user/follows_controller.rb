# frozen_string_literal: true

class Api::V1::User::FollowsController < Api::V1::User::ApplicationController
  before_action :set_followable, only: [:create]
  before_action :set_follow_and_followable, only: %i[show destroy]

  def index
    query = current_user.follows.unblocked.not_deleted
    query = query.for_followable_type(params[:followable_type]) unless params[:followable_type].nil?
    @count = query.count
    order_by = %w[created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
    @follows = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset).preload(:followable)
  end

  def show
  end

  def create
    @follow = current_user.follow(@followable)
    raise "You cannot follow this #{params[:followable_type]}" if @follow.blank?

    render :show
  end

  def destroy
    raise "You cannot follow this #{params[:followable_type]}" unless current_user.stop_following(@followable)

    render :show
  end

  private

  def set_followable
    case params[:followable_type].to_s.downcase
    when 'user'
      @followable = ::User.find params[:followable_id]
    when 'channel'
      @followable = Channel.find params[:followable_id]
    when 'organization'
      @followable = ::Organization.find params[:followable_id]
    else
      raise 'Unprocessible followable_type'
    end
  end

  def set_follow_and_followable
    if params[:id].present?
      @follow = current_user.follows.unblocked.not_deleted.find params[:id]
      @followable = @follow.followable
    else
      set_followable
      raise 'followable model is not set' if @followable.blank?

      @follow = current_user.follows.unblocked.not_deleted.for_followable(@followable).first
      if @follow.blank?
        raise(ActiveRecord::RecordNotFound,
              "Cannot find followable #{params[:followable_type]} with id ##{params[:followable_id]} for current user")
      end
    end
  end
end
