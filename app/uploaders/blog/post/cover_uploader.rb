# frozen_string_literal: true

class Blog::Post::CoverUploader < Uploader
  process convert: 'jpg'
  process :optimize

  def extension_white_list
    carrierwave_extension_white_list + %w[tif tiff gif fcgi]
  end

  def default_url
    ActionController::Base.helpers.asset_path 'channels/default_cover.png'
  end

  version :thumbnail_preview do
    process :rotate
    process :cropper
    process resize_to_fill: [340, 190]
    process :optimize
  end
  version :thumbnail do
    process :rotate
    process :cropper
    process resize_to_fill: [580, 295]
    process :optimize
  end
  version :medium do
    process :rotate
    process :cropper
    process resize_to_fill: [1190, 607]
    process :optimize
  end
  version :large do
    process :rotate
    process :cropper
    process resize_to_fill: [1600, 816]
    process :optimize
  end
end
