# frozen_string_literal: true
class UserImage < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :user, touch: true

  mount_uploader :original_image, UserAvatarUploader
  alias_attribute :carrierwave_id, :user_id

  validate :image_dimensions_and_size_validity, if: :original_image_changed?

  def cropping?
    crop_x.present? && crop_y.present? && crop_w.present? && crop_h.present?
  end

  def small_avatar_url
    original_image.small.url
  end

  def medium_avatar_url
    original_image.medium.url
  end

  def large_avatar_url
    original_image.large.url
  end

  def main_filename
    attributes['original_image']
  end

  private

  def image_dimensions_and_size_validity
    if original_image.file.size.to_f > 10.megabytes.to_f
      errors.add(:image, 'should be a maximum size of 10Mb')
      return
    end

    # because of invalid filetype
    # just exit here because it is validated by checking extension_white_list
    return if original_image.path.nil?

    begin
      magick_image = MiniMagick::Image.open(original_image.path)

      if magick_image.width < 280 || magick_image.height < 280
        errors.add(:image, 'should be at least 280x280 px')
      end
    rescue MiniMagick::Invalid => e
      Rails.logger.info e.message
    end
  end
end
