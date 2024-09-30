# frozen_string_literal: true

class Api::V1::Organization::ChannelsController < Api::V1::Organization::ApplicationController
  before_action :set_channel, only: %i[show update destroy]

  def index
    query = current_organization.channels
    @count = query.count
    @channels = query.limit(@limit).offset(@offset)
  end

  def show
  end

  def create
    @channel = current_organization.channels.build(channel_params)
    @channel.category = ChannelCategory.first
    @channel.status = Channel::Statuses::APPROVED
    @channel.save!
    render :show
  end

  def update
    @channel.update!(channel_params)
    render :show
  end

  def destroy
    @channel.destroy
    render :show
  end

  private

  def set_channel
    @channel = current_organization.channels.find(params[:id])
  end

  def channel_params
    params.require(:channel).permit(
      :title,
      :description
    )
  end
end
