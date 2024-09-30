# frozen_string_literal: true
class OrganizationLogo < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :organization, touch: true

  validate :image_dimensions_and_size_validity, if: :image?, on: :create

  mount_uploader :original, Uploader
  mount_uploader :image, CompanyLogoUploader
  alias_attribute :carrierwave_id, :organization_id

  def as_json
    {
      id: id,
      medium_url: medium_url
    }
  end

  def cropping?
    crop_x.present? && crop_y.present? && crop_w.present? && crop_h.present?
  end

  def small_url
    image.small.url
  end

  def medium_url
    image.medium.url
  end

  # def large_url
  #   ActionController::Base.helpers.asset_path(super)
  # end

  def main_filename
    attributes['image']
  end

  private

  def image_dimensions_and_size_validity
    if image.file.size.to_f > 10.megabytes.to_f
      errors.add(:image, "Image #{image.file.original_filename} should be a maximum size of 10Mb")
      return
    end

    # because of invalid filetype
    # just exit here because it is validated by checking extension_white_list
    return if image.path.nil?

    begin
      magick_image = MiniMagick::Image.open(image.path)

      if magick_image.width < 100 || magick_image.height < 100
        errors.add(:image, "Image #{image.file.original_filename} should be 300x300 minimum")
      end
    rescue MiniMagick::Invalid => e
      Rails.logger.info e.message
    end
  end

  # def image_has_not_changed
  #   if image_changed?
  #     errors.add(:image, 'Image can not be updated.')
  #     false
  #   end
  # end
end
