# frozen_string_literal: true

class Spa::ChannelsController < Spa::ApplicationController
  def show
    redirect_to root_path, flash: { error: 'Access denied' } unless valid_channel_request?
    @organization = channel&.organization
  end

  private

  def channel
    @channel ||= Channel.friendly.find(params[:id].to_s.downcase)
  end

  def valid_channel_request?
    channel.present? && current_ability.can?(:read, channel)
  end
end
