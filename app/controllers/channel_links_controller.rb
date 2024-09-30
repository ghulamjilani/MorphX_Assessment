# frozen_string_literal: true

class ChannelLinksController < ApplicationController
  def create
    link = ChannelLink.new(link_params)
    link.fetch_oembed_type

    if %w[error link].include?(link.oembed_type)
      responder = proc { render json: { error: "Sorry, but url #{link.url} is unreachable" }, status: 422 }
    elsif link.oembed_type == ChannelLink::OembedTypes::PHOTO
      # Skip this for now.
      # When use instagram photo url (eg.) o.remote_image_url = link.url raises error because that url returns html content
      # but Embedly gem can parse this url and build embed html & thumbnail_url
      o = ChannelImage.new
      o.remote_image_url = link.url
      responder = if o.valid?
                    proc { render json: link.channel_material }
                  else
                    proc { render json: { error: o.errors[:image].first }, status: 422 }
                  end
    else
      responder = proc { render json: link.channel_material(params[:width]) }
    end
    respond_to do |format|
      format.json(&responder)
    end
  end

  private

  def link_params
    params.require(:channel_link).permit(:url)
  end
end
