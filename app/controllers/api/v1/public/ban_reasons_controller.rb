# frozen_string_literal: true

class Api::V1::Public::BanReasonsController < Api::V1::Public::ApplicationController
  def index
    @count = BanReason.count
    order_by = %w[id name created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
    @ban_reasons = BanReason.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
  end

  def show
    @ban_reason = BanReason.find(params[:id])
  end
end
