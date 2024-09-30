# frozen_string_literal: true

class BecomePresenter::SaveChannelLink
  def initialize(user, channel, params)
    @user = user
    @params = params
    @channel = channel
    @errors = []
  end

  def execute
    return false if @params.blank?

    @link = if @params[:id]
              @channel.channel_links.find(@params[:id])
            else
              @channel.channel_links.new
            end
    @link.attributes = @params
    @link.fetch_oembed_type

    if @link.oembed_type.eql? 'error'
      @errors << "Sorry, but url #{@link.url} is unreachable."
      false
    elsif @link.oembed_type == ChannelLink::OembedTypes::PHOTO
      @image = @channel.images.new
      @image.remote_image_url = @link.url
      @image.is_main = false
      if @image.save
        true
      else
        false
      end
    elsif @link.save
      true
    else
      false
    end
  end

  def result
    if @link.persisted?
      @link.channel_material
    else
      @image.channel_material
    end
  end

  def errors
    @errors << @link.errors.full_messages if @link && @link.errors.present?
    @errors << @image.errors.full_messages if @image && @image.errors.present?
    @errors.flatten.compact.uniq.join('. ')
  end
end
