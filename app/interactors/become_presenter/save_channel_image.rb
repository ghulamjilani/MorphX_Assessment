# frozen_string_literal: true

class BecomePresenter::SaveChannelImage
  def initialize(user, channel, params)
    @user = user
    @params = params
    @channel = channel
    @errors = []
  end

  def execute
    return false if @params.blank?

    @image = if @params[:id]
               @channel.images.find(@params[:id])
             else
               @channel.images.new
             end
    @image.attributes = @params
    if @image.save
      true
    else
      Rails.logger.debug errors
      false
    end
  end

  def image
    @image.channel_material
  end

  def errors
    @errors << @image.errors.full_messages if @image && @image.errors.present?
    @errors.flatten.compact.uniq.join('. ')
  end
end
