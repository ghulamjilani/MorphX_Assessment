# frozen_string_literal: true
class ChannelLogo < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :channel

  validate :image_dimensions_and_size_validity, if: :original?, on: :create

  mount_uploader :original, Channel::LogoUploader
  alias_attribute :carrierwave_id, :channel_id

  def as_json
    {
      id: id,
      original_url: original_url,
      small_url: small_url,
      large_url: large_url
    }
  end

  def form_data
    {
      id: id,
      image_src: small_url
    }
  end

  def cropping?
    crop_x.present? && crop_y.present? && crop_w.present? && crop_h.present?
  end

  def small_url
    original.small.url
  end

  def large_url
    original.large.url
  end

  def main_filename
    attributes['original']
  end

  private

  def image_dimensions_and_size_validity
    if original.file.size.to_f > 10.megabytes.to_f
      errors.add(:original, "Image #{original.file.original_filename} should be a maximum size of 10Mb")
      return
    end

    # because of invalid filetype
    # just exit here because it is validated by checking extension_white_list
    return if original.path.nil?

    begin
      magick_image = MiniMagick::Image.open(original.path)

      if magick_image.width < 100 || magick_image.height < 100
        errors.add(:original, "Image #{original.file.original_filename} should be 100x100 minimum")
      end
    rescue MiniMagick::Invalid => e
      Rails.logger.info e.message
    end
  end
end
