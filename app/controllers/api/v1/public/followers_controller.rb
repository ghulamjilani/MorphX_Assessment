# frozen_string_literal: true

class Api::V1::Public::FollowersController < Api::V1::Public::ApplicationController
  before_action :set_followable

  def index
    query = @followable.user_followers
    @count = query.count
    order_by = %w[created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
    @followers = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
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
      raise 'Unprocessable followable_type'
    end
  end
end
