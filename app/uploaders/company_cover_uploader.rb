# frozen_string_literal: true

class CompanyCoverUploader < Uploader
  process convert: 'jpg'
  process :optimize

  def extension_white_list
    carrierwave_extension_white_list + %w[tif tiff gif fcgi]
  end

  def default_url
    ActionController::Base.helpers.asset_path 'channels/default_cover.png'
  end

  version :small do
    process :rotate
    process :cropper
    process resize_to_fill: [280, 280]
    process :optimize
  end
  version :medium do
    process :rotate
    process :cropper
    process resize_to_fill: [1250, 350]
    process :optimize
  end
  version :large do
    process :rotate
    process :cropper
    process resize_to_fill: [1400, 600]
    process :optimize
  end
end
