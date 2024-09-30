# frozen_string_literal: true
class CompanySetting < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :organization, touch: true
  mount_uploader :logo_image, Uploader
  alias_attribute :carrierwave_id, :organization_id
end
