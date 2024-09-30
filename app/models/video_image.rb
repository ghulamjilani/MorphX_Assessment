# frozen_string_literal: true
class VideoImage < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  after_validation :set_versions
  belongs_to :video, touch: true

  SOURCE_TYPES = {
    custom: 0, # uploaded
    frame: 1 # selected from timeline
  }.freeze
  mount_uploader :image, VideoImageUploader
  # process_in_background :image
  mount_uploader :original_image, Uploader

  alias_attribute :carrierwave_id, :video_id

  def cropping?
    source_type == SOURCE_TYPES[:custom] && crop_x.present? && crop_y.present? && crop_w.present? && crop_h.present?
  end

  def main_filename
    attributes['image']
  end

  private

  def set_versions
    self.original_image = image.file if self&.image&.file
  end
end
