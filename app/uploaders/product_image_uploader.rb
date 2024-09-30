# frozen_string_literal: true

class ProductImageUploader < Uploader
  process convert: 'jpg'
  process :optimize

  def extension_white_list
    carrierwave_extension_white_list + %w[tif tiff gif fcgi]
  end

  def default_url
    ActionController::Base.helpers.asset_path 'product/default_product.jpg'
  end
end
