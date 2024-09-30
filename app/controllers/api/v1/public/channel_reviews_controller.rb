# frozen_string_literal: true

class Api::V1::Public::ChannelReviewsController < Api::V1::Public::ApplicationController
  before_action :set_channel

  def index
    @reviews = @channel.reviews_with_rates.where.not(reviews: { overall_experience_comment: nil }).where(rates: { dimension: ::Rate::RateKeys::QUALITY_OF_CONTENT }).limit(@limit).offset(@offset)
  end

  private

  def set_channel
    @channel = Channel.find(params[:channel_id])
  end
end
