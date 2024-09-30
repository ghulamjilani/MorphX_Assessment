# frozen_string_literal: true

class Api::V1::Public::ChannelSubscriptionPlansController < Api::V1::Public::ApplicationController
  before_action :set_channel

  def index
    @subscription = @channel.subscription
    @plans = @subscription.plans.active.order(amount: :asc) if @subscription.present?
  end

  def show
    @plan = @channel.subscription.plans.active.find(params[:id])
  end

  private

  def set_channel
    @channel = Channel.find(params[:channel_id])
  end
end
