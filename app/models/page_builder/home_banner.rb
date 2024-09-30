# frozen_string_literal: true
class PageBuilder::HomeBanner < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  self.table_name_prefix = 'pb_'

  VERSIONS = %w[main].freeze

  mount_uploader :file, PageBuilder::HomeBannerUploader
  alias_attribute :carrierwave_id, :id

  def cropping?
    crop_x.present? && crop_y.present? && crop_w.present? && crop_h.present?
  end
end
