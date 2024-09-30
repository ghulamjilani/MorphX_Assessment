# frozen_string_literal: true

class VideoImageUploader < Uploader
  process convert: 'jpg'
  process :optimize

  def default_url
    ActionController::Base.helpers.asset_path 'videoDefaultImg.jpg'
  end

  version :small do
    process :rotate
    process :cropper
    process resize_to_fill: [400, 225]
    process :optimize
  end
  version :medium do
    process :rotate
    process :cropper
    process resize_to_fill: [720, 405]
    process :optimize
  end
  version :large do
    process :rotate
    process :cropper
    process resize_to_fill: [1440, 810]
    process :optimize
  end
  version :player do
    process :rotate
    process :cropper
    process resize_to_fill: [880, 495]
    process :optimize
  end
end
