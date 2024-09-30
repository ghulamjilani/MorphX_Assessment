# frozen_string_literal: true
class PageBuilder::AdBanner < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  self.table_name_prefix = 'pb_'

  mount_uploader :file, PageBuilder::AdBannerUploader
  alias_attribute :carrierwave_id, :id

  has_many :ad_clicks, foreign_key: :pb_ad_banner_id, dependent: :destroy

  scope :active, -> { where(archived: false) }
end
