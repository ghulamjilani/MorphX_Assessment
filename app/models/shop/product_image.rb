# frozen_string_literal: true
class Shop::ProductImage < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :product, class_name: 'Shop::Product'

  mount_uploader :original, ProductImageUploader
  alias_attribute :carrierwave_id, :product_id

  def image_url
    ActionController::Base.helpers.asset_path(original_url)
  end

  def main_filename
    attributes['original']
  end
end
