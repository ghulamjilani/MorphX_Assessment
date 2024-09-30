# frozen_string_literal: true

class PageBuilder::AdBannerUploader < Uploader
  process convert: :jpg
  process :optimize

  def default_url
    ActionController::Base.helpers.asset_path 'channels/default_cover.png'
  end

  version :small do
    # process :rotate
    # process :cropper
    process resize_to_fill: [400, 225]
    process :optimize
  end
end
