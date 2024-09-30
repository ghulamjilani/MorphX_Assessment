# frozen_string_literal: true
class Blog::PostCover < Blog::ApplicationRecord
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :post, class_name: 'Blog::Post', foreign_key: 'blog_post_id', inverse_of: :cover, touch: true,
                    required: true

  validate :image_dimensions_and_size_validity, if: :image?, on: :create

  mount_uploader :image, Blog::Post::CoverUploader
  alias_attribute :carrierwave_id, :blog_post_id

  def cropping?
    crop_x.present? && crop_y.present? && crop_w.present? && crop_h.present?
  end

  def image_thumbnail_preview_url
    image.thumbnail_preview.url
  end

  def image_thumbnail_url
    image.thumbnail.url
  end

  def image_medium_url
    image.medium.url
  end

  def image_large_url
    image.large.url
  end

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

      if magick_image.width < 300 || magick_image.height < 300
        errors.add(:image, "Image #{image.file.original_filename} should be 300x300 minimum")
      end
    rescue MiniMagick::Invalid => e
      Rails.logger.info e.message
    end
  end
end
