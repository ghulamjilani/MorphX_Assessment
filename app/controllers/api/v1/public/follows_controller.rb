# frozen_string_literal: true

class Api::V1::Public::FollowsController < Api::V1::Public::ApplicationController
  before_action :set_follower

  def index
    query = @follower.follows.unblocked.not_deleted
    query = query.for_followable_type(params[:followable_type].classify) unless params[:followable_type].nil?
    @count = query.count
    order_by = %w[created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
    @follows = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset).preload(:followable)
  end

  private

  def set_follower
    case params[:follower_type].to_s.downcase
    when 'user'
      @follower = ::User.find params[:follower_id]
      # when 'channel'
      #   @follower = Channel.find params[:follower_id]
      # when 'organization'
      #   @follower = Organization.find params[:follower_id]
    else
      raise "Unprocessable follower_type '#{params[:follower_type]}', available types: 'user'"
    end
  end
end
