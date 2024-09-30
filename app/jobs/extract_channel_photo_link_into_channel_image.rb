# frozen_string_literal: true

class ExtractChannelPhotoLinkIntoChannelImage < ApplicationJob
  def perform(channel_link_id)
    channel_link = ChannelLink.find(channel_link_id)

    o                  = ChannelImage.new
    o.description      = channel_link.description
    o.place_number     = channel_link.place_number
    o.channel_id = channel_link.channel_id
    o.remote_image_url = channel_link.url

    if o.valid?
      o.save!

      channel_link.destroy
    else
      raise "#{o.errors.full_messages.inspect} stopped channel image from being created"
    end
  end
end
