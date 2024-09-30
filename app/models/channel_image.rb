# frozen_string_literal: true
class ChannelImage < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::HasPostgresLoImage
  include ModelConcerns::ActiveModel::Extensions

  VERSIONS = %w[image image_gallery image_home_slider image_preview image_session_slider original_image].freeze

  # set versions files after validation because we don't need them for validation
  after_validation :set_versions, on: :create

  belongs_to :channel, touch: true

  validate :image_dimensions_and_size_validity, if: :image?, on: :create

  # Do not allow image updating(by workflow).
  # validate :image_has_not_changed, on: :update

  scope :most_relevant, -> { order(place_number: :asc) }

  mount_uploader :image, Channel::ImageUploader
  # process_in_background :image
  mount_uploader :original_image, Uploader

  alias_attribute :carrierwave_id, :channel_id

  def cropping?
    crop_x.present? && crop_y.present? && crop_w.present? && crop_h.present?
  end

  def gallery_item
    {
      id: id,
      image_src: image_preview_url,
      place_number: place_number,
      description: description,
      is_main: is_main
    }.tap do |material|
      material[:origin_src] = image_url if image_processing?
    end
  end

  def channel_material
    {
      id: id,
      img_src: image_gallery_url,
      type: 'image',
      place_number: place_number,
      description: description,
      is_main: is_main
    }.tap do |material|
      material[:origin_src] = image_url if image_processing?
    end
  end

  def slider_material
    {
      id: id,
      img_src: image_url,
      type: 'image',
      place_number: place_number,
      description: description,
      is_main: is_main
    }.tap do |material|
      material[:origin_src] = image_url if image_processing?
    end
  end

  def image_preview_url
    image_processing? ? image.url : image.preview.url
  end

  def image_mobile_preview_url
    image_processing? ? image.url : image.mobile_preview.url
  end

  def image_slider_url
    image_processing? ? image.url : image.slider.url
  end

  def image_gallery_url
    image_processing? ? image.url : image.gallery.url
  end

  def image_tile_url
    image_processing? ? image.url : image.tile.present? ? image.tile.url : image_gallery_url
  end

  def main_filename
    attributes['image']
  end

  private

  def set_versions
    self.original_image = image.file
  end

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

      if is_main? && (magick_image.width < 415 || magick_image.height < 115)
        errors.add(:image, "Cover #{image.file.original_filename} should be 415x115px minimum")
      elsif !is_main? && (magick_image.width < 300 || magick_image.height < 150)
        errors.add(:image, "Gallery Image #{image.file.original_filename} should be 300x150px minimum")
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
