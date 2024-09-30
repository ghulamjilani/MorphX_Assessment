# frozen_string_literal: true

class Blog::Post::ImageUploader < Uploader
  process convert: 'jpg'
  process :optimize

  def extension_white_list
    carrierwave_extension_white_list + %w[tif tiff gif fcgi]
  end

  version :large do
    process convert: 'jpg'
    process resize_to_limit: [1000, 1000]
    process :optimize
  end
end
