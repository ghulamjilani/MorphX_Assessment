# frozen_string_literal: true

class Channel::ImageUploader < Uploader
  process convert: :jpg
  process :optimize

  def is_main?
    model.is_main?
  end

  def default_url
    ActionController::Base.helpers.asset_path 'channels/default_cover.png'
  end

  version :slider do
    process :rotate
    process :cropper
    process resize_to_fill: [410, 230]
    process :optimize
  end
  version :preview do
    process :rotate
    process :cropper
    process resize_to_fill: [280, 280]
    process :optimize
  end
  version :tile do
    process :rotate
    process :cropper
    process resize_to_fill: [485, 135]
    process :optimize
  end
  version :gallery do
    process :rotate
    process :cropper
    process resize_to_fill: [1250, 350]
    process :optimize
  end
  version :mobile_preview do
    process :rotate
    process :cropper
    process resize_to_fill: [700, 300]
    process :optimize
  end
end
