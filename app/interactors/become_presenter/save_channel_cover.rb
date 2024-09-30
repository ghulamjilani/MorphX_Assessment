# frozen_string_literal: true

class BecomePresenter::SaveChannelCover
  def initialize(user, channel, params)
    @user = user
    @params = params
    @channel = channel
    @errors = []
  end

  def execute
    return false if @params.empty? || @params[:image].blank?

    if is_valid?
      @channel.cover_attributes = @params
      if @channel.cover.save
        true
      else
        false
      end
    else
      false
    end
  end

  def cover
    @channel.cover.channel_material
  end

  def errors
    @errors << @channel.cover.errors.full_messages if @channel.cover && @channel.cover.errors.present?
    @errors.flatten.compact.uniq.join('. ')
  end

  def is_valid?
    cover = ChannelImage.new(@params)
    # check it without assigning nested attributes to channel
    # because it removes previous cover before new validated
    valid = cover.valid?
    @errors << cover.errors.full_messages if cover && !valid
    valid
  end
end
